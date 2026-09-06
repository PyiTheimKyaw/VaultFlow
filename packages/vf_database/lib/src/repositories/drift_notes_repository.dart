import 'package:drift/drift.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/src/daos/notes_dao.dart';
import 'package:vf_database/src/daos/outbox_dao.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_database/src/repositories/mappers.dart';
import 'package:vf_domain/vf_domain.dart';

/// [NotesRepository] on Drift; same transactional outbox contract as
/// `DriftVaultRepository`.
class DriftNotesRepository implements NotesRepository {
  DriftNotesRepository(this._db);

  final VaultFlowDatabase _db;

  NotesDao get _notes => _db.notesDao;
  OutboxDao get _outbox => _db.outboxDao;

  @override
  Stream<List<Note>> watchAllNotes() =>
      _notes.watchAllLive().map((rows) => rows.map(Mappers.note).toList());

  @override
  Stream<List<Note>> watchNotesIn(String? folderId) =>
      _notes.watchIn(folderId).map((rows) => rows.map(Mappers.note).toList());

  @override
  Stream<Note?> watchNote(String id) =>
      _notes.watchById(id).map((r) => r == null ? null : Mappers.note(r));

  @override
  Future<Note?> getNote(String id) async {
    final row = await _notes.getById(id);
    return row == null ? null : Mappers.note(row);
  }

  @override
  Future<List<Note>> search(String query) async =>
      (await _notes.search(query)).map(Mappers.note).toList();

  @override
  Future<void> createNote(Note note) => _db.transaction(() async {
    await _notes.insertRow(
      Mappers.noteCompanion(
        note.copyWith(syncStatus: SyncStatus.pending, version: 0),
      ),
    );
    final row = (await _notes.getById(note.id))!;
    await _outbox.enqueue(
      entityType: EntityType.note,
      entityId: note.id,
      op: SyncOp.create,
      payload: Mappers.notePayload(row),
      baseVersion: 0,
      now: note.createdAt,
    );
  });

  @override
  Future<void> saveNote(
    String id, {
    required String title,
    required String body,
    required DateTime now,
  }) =>
      _update(id, NotesCompanion(title: Value(title), body: Value(body)), now);

  @override
  Future<void> moveNote(String id, String? folderId, DateTime now) => _update(
    id,
    NotesCompanion(folderId: Value(folderId)),
    now,
    op: SyncOp.move,
    movePayload: {'folder_id': folderId},
  );

  Future<void> _update(
    String id,
    NotesCompanion changes,
    DateTime now, {
    SyncOp op = SyncOp.update,
    Map<String, Object?>? movePayload,
  }) => _db.transaction(() async {
    final before = await _require(id);
    await _notes.updateRow(
      id,
      changes.copyWith(
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    final after = (await _notes.getById(id))!;
    await _outbox.enqueue(
      entityType: EntityType.note,
      entityId: id,
      op: op,
      payload: op == SyncOp.move ? movePayload! : Mappers.notePayload(after),
      baseVersion: before.version,
      now: now,
    );
  });

  @override
  Future<void> deleteNote(String id, DateTime now) => _db.transaction(() async {
    final row = await _require(id);
    await _notes.updateRow(
      id,
      NotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    await _outbox.enqueue(
      entityType: EntityType.note,
      entityId: id,
      op: SyncOp.delete,
      payload: const <String, Object?>{},
      baseVersion: row.version,
      now: now,
    );
  });

  Future<NoteRow> _require(String id) async {
    final row = await _notes.getById(id);
    if (row == null || row.deletedAt != null) {
      throw NotFoundFailure('Note $id not found');
    }
    return row;
  }
}
