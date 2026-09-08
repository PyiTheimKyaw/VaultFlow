import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_database/src/repositories/mappers.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Row-level operations the sync engine needs that go around the outbox:
/// applying server snapshots and recording push outcomes. Everything here is
/// server-authoritative, so nothing is enqueued.
class DriftSyncRepository {
  DriftSyncRepository(this._db);

  final VaultFlowDatabase _db;

  VaultFlowDatabase get db => _db;

  /// Writes a server snapshot for [type] as `synced` with [version].
  /// Documents keep their local cache columns.
  Future<void> applyRemoteSnapshot(
    EntityType type,
    Map<String, Object?> snapshot, {
    required int version,
  }) async {
    switch (type) {
      case EntityType.folder:
        final dto = FolderDto.fromJson({...snapshot, 'version': version});
        await _db.foldersDao.upsertRow(
          FoldersCompanion.insert(
            id: dto.id,
            name: dto.name,
            parentId: Value(dto.parentId),
            version: Value(version),
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: Value(dto.deletedAt),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
      case EntityType.document:
        final dto = DocumentDto.fromJson({...snapshot, 'version': version});
        await _db.documentsDao.upsertRow(
          DocumentsCompanion.insert(
            id: dto.id,
            name: dto.name,
            folderId: Value(dto.folderId),
            mimeType: dto.mimeType,
            sizeBytes: dto.sizeBytes,
            sha256: dto.sha256,
            storageKey: Value(dto.storageKey),
            version: Value(version),
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: Value(dto.deletedAt),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
      case EntityType.note:
        final dto = NoteDto.fromJson({...snapshot, 'version': version});
        await _db.notesDao.upsertRow(
          NotesCompanion.insert(
            id: dto.id,
            title: dto.title,
            body: dto.body,
            folderId: Value(dto.folderId),
            version: Value(version),
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: Value(dto.deletedAt),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
    }
  }

  /// After a push was `applied`: record the server version. The row stays
  /// `pending` when a newer outbox row for it already exists.
  Future<void> markApplied(
    EntityType type,
    String id, {
    required int version,
  }) async {
    final stillPending = await _db.outboxDao.hasPending(type, id);
    final status = stillPending ? SyncStatus.pending : SyncStatus.synced;
    await _setVersionAndStatus(type, id, version: version, status: status);
  }

  Future<void> markConflicted(EntityType type, String id) =>
      _setVersionAndStatus(type, id, status: SyncStatus.conflicted);

  Future<void> markPending(EntityType type, String id) =>
      _setVersionAndStatus(type, id, status: SyncStatus.pending);

  Future<void> markSynced(EntityType type, String id, {int? version}) =>
      _setVersionAndStatus(
        type,
        id,
        version: version,
        status: SyncStatus.synced,
      );

  Future<void> _setVersionAndStatus(
    EntityType type,
    String id, {
    required SyncStatus status,
    int? version,
  }) {
    final v = version == null ? const Value<int>.absent() : Value(version);
    return switch (type) {
      EntityType.folder => _db.foldersDao.updateRow(
        id,
        FoldersCompanion(version: v, syncStatus: Value(status)),
      ),
      EntityType.document => _db.documentsDao.updateRow(
        id,
        DocumentsCompanion(version: v, syncStatus: Value(status)),
      ),
      EntityType.note => _db.notesDao.updateRow(
        id,
        NotesCompanion(version: v, syncStatus: Value(status)),
      ),
    };
  }

  /// Current local snapshot in wire shape, or `null` if the row is missing.
  Future<Map<String, Object?>?> localSnapshot(
    EntityType type,
    String id,
  ) async {
    switch (type) {
      case EntityType.folder:
        final row = await _db.foldersDao.getById(id);
        return row == null ? null : Mappers.folderPayload(row);
      case EntityType.document:
        final row = await _db.documentsDao.getById(id);
        return row == null ? null : Mappers.documentPayload(row);
      case EntityType.note:
        final row = await _db.notesDao.getById(id);
        return row == null ? null : Mappers.notePayload(row);
    }
  }

  Future<void> recordConflict({
    required String id,
    required EntityType type,
    required String entityId,
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
    required int remoteVersion,
    required DateTime now,
  }) => _db.conflictsDao.insertRow(
    ConflictsCompanion.insert(
      id: id,
      entityType: type,
      entityId: entityId,
      localSnapshot: local,
      remoteSnapshot: remote,
      remoteVersion: remoteVersion,
      createdAt: now,
    ),
  );

  Stream<List<Conflict>> watchConflicts() => _db.conflictsDao
      .watchUnresolved()
      .map((rows) => rows.map(Mappers.conflict).toList());

  Future<Conflict?> getConflict(String id) async {
    final row = await _db.conflictsDao.getById(id);
    return row == null ? null : Mappers.conflict(row);
  }
}
