import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$NotesDaoMixin {
  NotesDao(super.attachedDatabase);

  SimpleSelectStatement<$NotesTable, NoteRow> _selectLive() =>
      select(notes)..where((n) => n.deletedAt.isNull());

  Future<List<NoteRow>> getAllLive() =>
      (_selectLive()..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])).get();

  Stream<List<NoteRow>> watchAllLive() =>
      (_selectLive()..orderBy([(n) => OrderingTerm.desc(n.updatedAt)])).watch();

  Future<List<NoteRow>> getIn(String? folderId) =>
      (_selectLive()
            ..where(
              (n) => folderId == null
                  ? n.folderId.isNull()
                  : n.folderId.equals(folderId),
            )
            ..orderBy([(n) => OrderingTerm.asc(n.title.lower())]))
          .get();

  Stream<List<NoteRow>> watchIn(String? folderId) =>
      (_selectLive()
            ..where(
              (n) => folderId == null
                  ? n.folderId.isNull()
                  : n.folderId.equals(folderId),
            )
            ..orderBy([(n) => OrderingTerm.asc(n.title.lower())]))
          .watch();

  Future<List<NoteRow>> getInAny(Iterable<String?> folderIds) {
    final ids = folderIds.whereType<String>().toList();
    final includeRoot = folderIds.contains(null);
    return (_selectLive()..where(
          (n) => includeRoot
              ? n.folderId.isNull() | n.folderId.isIn(ids)
              : n.folderId.isIn(ids),
        ))
        .get();
  }

  Stream<NoteRow?> watchById(String id) =>
      (select(notes)..where((n) => n.id.equals(id))).watchSingleOrNull();

  Future<NoteRow?> getById(String id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(NotesCompanion row) => into(notes).insert(row);

  Future<void> updateRow(String id, NotesCompanion changes) =>
      (update(notes)..where((n) => n.id.equals(id))).write(changes);

  Future<void> upsertRow(NotesCompanion row) =>
      into(notes).insertOnConflictUpdate(row);

  /// FTS5 prefix search over title and body, best matches first.
  Future<List<NoteRow>> search(String query) {
    final match = toFtsQuery(query);
    if (match.isEmpty) return Future.value(const []);
    return customSelect(
      'SELECT n.* FROM notes n '
      'JOIN notes_fts f ON f.rowid = n.rowid '
      'WHERE notes_fts MATCH ? AND n.deleted_at IS NULL '
      'ORDER BY f.rank',
      variables: [Variable.withString(match)],
      readsFrom: {notes},
    ).map((row) => notes.map(row.data)).get();
  }

  /// Turns free text into a safe FTS5 expression: every token becomes a
  /// quoted prefix term, so user input can never inject FTS operators.
  static String toFtsQuery(String raw) {
    final tokens = raw
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll('"', '').trim())
        .where((t) => t.isNotEmpty);
    return tokens.map((t) => '"$t"*').join(' ');
  }
}
