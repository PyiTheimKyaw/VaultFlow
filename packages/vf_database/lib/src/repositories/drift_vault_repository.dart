import 'package:drift/drift.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/src/daos/documents_dao.dart';
import 'package:vf_database/src/daos/folders_dao.dart';
import 'package:vf_database/src/daos/notes_dao.dart';
import 'package:vf_database/src/daos/outbox_dao.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_database/src/repositories/mappers.dart';
import 'package:vf_domain/vf_domain.dart';

/// [VaultRepository] on Drift. Every mutation runs in one transaction that
/// writes the entity row, flips its `sync_status` to pending and enqueues
/// the outbox op.
class DriftVaultRepository implements VaultRepository {
  DriftVaultRepository(this._db);

  final VaultFlowDatabase _db;

  FoldersDao get _folders => _db.foldersDao;
  DocumentsDao get _documents => _db.documentsDao;
  NotesDao get _notes => _db.notesDao;
  OutboxDao get _outbox => _db.outboxDao;

  @override
  Stream<List<Folder>> watchAllFolders() =>
      _folders.watchAllLive().map((rows) => rows.map(Mappers.folder).toList());

  @override
  Stream<Folder?> watchFolder(String id) =>
      _folders.watchById(id).map((r) => r == null ? null : Mappers.folder(r));

  @override
  Future<Folder?> getFolder(String id) async {
    final row = await _folders.getById(id);
    return row == null || row.deletedAt != null ? null : Mappers.folder(row);
  }

  @override
  Future<List<Folder>> getAncestors(String folderId) async {
    final chain = <Folder>[];
    final seen = <String>{};
    String? current = folderId;
    while (current != null && seen.add(current)) {
      final row = await _folders.getById(current);
      if (row == null) break;
      chain.insert(0, Mappers.folder(row));
      current = row.parentId;
    }
    return chain;
  }

  @override
  Stream<FolderContents> watchContents(String? folderId) {
    // A cheap trigger query that re-fires whenever any of the three tables
    // change; the actual rows are loaded in one go per emission.
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.folders, _db.documents, _db.notes},
        )
        .watch()
        .asyncMap((_) => _loadContents(folderId));
  }

  @override
  Future<List<Document>> listCachedDocuments() async =>
      (await _documents.getCached()).map(Mappers.document).toList();

  @override
  Stream<List<Document>> watchAllDocuments() => _documents.watchAllLive().map(
    (rows) => rows.map(Mappers.document).toList(),
  );

  @override
  Future<FolderContents> searchByName(String query, {int limit = 50}) async {
    final folders = await _folders.searchByName(query, limit: limit);
    final documents = await _documents.searchByName(query, limit: limit);
    return FolderContents(
      folderId: null,
      folders: folders.map(Mappers.folder).toList(),
      documents: documents.map(Mappers.document).toList(),
    );
  }

  Future<FolderContents> _loadContents(String? folderId) async {
    final folders = await _folders.getChildren(folderId);
    final documents = await _documents.getIn(folderId);
    final notes = await _notes.getIn(folderId);
    return FolderContents(
      folderId: folderId,
      folders: folders.map(Mappers.folder).toList(),
      documents: documents.map(Mappers.document).toList(),
      notes: notes.map(Mappers.note).toList(),
    );
  }

  @override
  Future<Document?> getDocument(String id) async {
    final row = await _documents.getById(id);
    return row == null ? null : Mappers.document(row);
  }

  @override
  Stream<Document?> watchDocument(String id) => _documents
      .watchById(id)
      .map((r) => r == null ? null : Mappers.document(r));

  // ---------------------------------------------------------------- folders

  @override
  Future<void> createFolder(Folder folder) => _db.transaction(() async {
    await _folders.insertRow(
      Mappers.folderCompanion(
        folder.copyWith(syncStatus: SyncStatus.pending, version: 0),
      ),
    );
    final row = (await _folders.getById(folder.id))!;
    await _outbox.enqueue(
      entityType: EntityType.folder,
      entityId: folder.id,
      op: SyncOp.create,
      payload: Mappers.folderPayload(row),
      baseVersion: 0,
      now: folder.createdAt,
    );
  });

  @override
  Future<void> renameFolder(String id, String name, DateTime now) =>
      _updateFolder(id, FoldersCompanion(name: Value(name)), now);

  @override
  Future<void> moveFolder(String id, String? parentId, DateTime now) =>
      _updateFolder(
        id,
        FoldersCompanion(parentId: Value(parentId)),
        now,
        op: SyncOp.move,
        movePayload: {'parent_id': parentId},
      );

  Future<void> _updateFolder(
    String id,
    FoldersCompanion changes,
    DateTime now, {
    SyncOp op = SyncOp.update,
    Map<String, Object?>? movePayload,
  }) => _db.transaction(() async {
    final before = await _requireFolder(id);
    await _folders.updateRow(
      id,
      changes.copyWith(
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    final after = (await _folders.getById(id))!;
    await _outbox.enqueue(
      entityType: EntityType.folder,
      entityId: id,
      op: op,
      payload: op == SyncOp.move ? movePayload! : Mappers.folderPayload(after),
      baseVersion: before.version,
      now: now,
    );
  });

  @override
  Future<void> deleteFolder(String id, DateTime now) =>
      _db.transaction(() async {
        final root = await _requireFolder(id);
        final descendants = await _folders.getDescendants(id);
        final folderIds = <String?>[id, ...descendants.map((f) => f.id)];

        for (final doc in await _documents.getInAny(folderIds)) {
          await _tombstoneDocument(doc, now);
        }
        for (final note in await _notes.getInAny(folderIds)) {
          await _tombstoneNote(note, now);
        }
        // Children first so the server never sees a child referencing a
        // tombstoned parent if it applies ops in order.
        for (final folder in [...descendants.reversed, root]) {
          await _folders.updateRow(
            folder.id,
            FoldersCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );
          await _outbox.enqueue(
            entityType: EntityType.folder,
            entityId: folder.id,
            op: SyncOp.delete,
            payload: const <String, Object?>{},
            baseVersion: folder.version,
            now: now,
          );
        }
      });

  Future<FolderRow> _requireFolder(String id) async {
    final row = await _folders.getById(id);
    if (row == null || row.deletedAt != null) {
      throw NotFoundFailure('Folder $id not found');
    }
    return row;
  }

  // -------------------------------------------------------------- documents

  /// [dependsOnTransfer] parks the create as `blocked` until that upload
  /// completes and fills in `storage_key`.
  @override
  Future<void> createDocument(Document document, {String? dependsOnTransfer}) =>
      _db.transaction(() async {
        await _documents.insertRow(
          Mappers.documentCompanion(
            document.copyWith(syncStatus: SyncStatus.pending, version: 0),
          ),
        );
        final row = (await _documents.getById(document.id))!;
        await _outbox.enqueue(
          entityType: EntityType.document,
          entityId: document.id,
          op: SyncOp.create,
          payload: Mappers.documentPayload(row),
          baseVersion: 0,
          now: document.createdAt,
          dependsOnTransfer: dependsOnTransfer,
        );
      });

  /// Records the object key once an upload finished: the row, and any
  /// outbox create still waiting on the transfer, learn the key; then the
  /// create is released.
  Future<void> attachStorageKey(
    String documentId, {
    required String storageKey,
    required String transferId,
    int? version,
  }) => _db.transaction(() async {
    await _documents.updateRow(
      documentId,
      DocumentsCompanion(
        storageKey: Value(storageKey),
        version: version == null ? const Value.absent() : Value(version),
      ),
    );
    await _outbox.patchBlockedPayload(transferId, {'storage_key': storageKey});
    await _outbox.unblock(transferId);
  });

  @override
  Future<void> renameDocument(String id, String name, DateTime now) =>
      _updateDocument(id, DocumentsCompanion(name: Value(name)), now);

  @override
  Future<void> moveDocument(String id, String? folderId, DateTime now) =>
      _updateDocument(
        id,
        DocumentsCompanion(folderId: Value(folderId)),
        now,
        op: SyncOp.move,
        movePayload: {'folder_id': folderId},
      );

  Future<void> _updateDocument(
    String id,
    DocumentsCompanion changes,
    DateTime now, {
    SyncOp op = SyncOp.update,
    Map<String, Object?>? movePayload,
  }) => _db.transaction(() async {
    final before = await _requireDocument(id);
    await _documents.updateRow(
      id,
      changes.copyWith(
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    final after = (await _documents.getById(id))!;
    await _outbox.enqueue(
      entityType: EntityType.document,
      entityId: id,
      op: op,
      payload: op == SyncOp.move
          ? movePayload!
          : Mappers.documentPayload(after),
      baseVersion: before.version,
      now: now,
    );
  });

  @override
  Future<void> deleteDocument(String id, DateTime now) =>
      _db.transaction(() async {
        final row = await _requireDocument(id);
        await _tombstoneDocument(row, now);
      });

  Future<void> _tombstoneDocument(DocumentRow row, DateTime now) async {
    await _documents.updateRow(
      row.id,
      DocumentsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    await _outbox.enqueue(
      entityType: EntityType.document,
      entityId: row.id,
      op: SyncOp.delete,
      payload: const <String, Object?>{},
      baseVersion: row.version,
      now: now,
    );
  }

  Future<void> _tombstoneNote(NoteRow row, DateTime now) async {
    await _notes.updateRow(
      row.id,
      NotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
    await _outbox.enqueue(
      entityType: EntityType.note,
      entityId: row.id,
      op: SyncOp.delete,
      payload: const <String, Object?>{},
      baseVersion: row.version,
      now: now,
    );
  }

  Future<DocumentRow> _requireDocument(String id) async {
    final row = await _documents.getById(id);
    if (row == null || row.deletedAt != null) {
      throw NotFoundFailure('Document $id not found');
    }
    return row;
  }

  @override
  Future<void> updateDocumentCache(
    String id, {
    required CacheState cacheState,
    String? localPath,
  }) => _documents.updateRow(
    id,
    DocumentsCompanion(
      cacheState: Value(cacheState),
      localPath: Value(localPath),
    ),
  );
}
