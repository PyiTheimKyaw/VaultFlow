import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Row ↔ entity ↔ wire-payload conversions.
abstract final class Mappers {
  static Folder folder(FolderRow r) => Folder(
    id: r.id,
    name: r.name,
    parentId: r.parentId,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
    syncStatus: r.syncStatus,
  );

  static FoldersCompanion folderCompanion(Folder f) => FoldersCompanion.insert(
    id: f.id,
    name: f.name,
    parentId: Value(f.parentId),
    version: Value(f.version),
    createdAt: f.createdAt,
    updatedAt: f.updatedAt,
    deletedAt: Value(f.deletedAt),
    syncStatus: Value(f.syncStatus),
  );

  /// Wire snapshot pushed to the server for create/update ops.
  static Map<String, Object?> folderPayload(FolderRow r) => FolderDto(
    id: r.id,
    name: r.name,
    parentId: r.parentId,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  ).toJson();

  static Document document(DocumentRow r) => Document(
    id: r.id,
    name: r.name,
    folderId: r.folderId,
    mimeType: r.mimeType,
    sizeBytes: r.sizeBytes,
    sha256: r.sha256,
    storageKey: r.storageKey,
    localPath: r.localPath,
    cacheState: r.cacheState,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
    syncStatus: r.syncStatus,
  );

  static DocumentsCompanion documentCompanion(Document d) =>
      DocumentsCompanion.insert(
        id: d.id,
        name: d.name,
        folderId: Value(d.folderId),
        mimeType: d.mimeType,
        sizeBytes: d.sizeBytes,
        sha256: d.sha256,
        storageKey: Value(d.storageKey),
        localPath: Value(d.localPath),
        cacheState: Value(d.cacheState),
        version: Value(d.version),
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        deletedAt: Value(d.deletedAt),
        syncStatus: Value(d.syncStatus),
      );

  static Map<String, Object?> documentPayload(DocumentRow r) => DocumentDto(
    id: r.id,
    name: r.name,
    folderId: r.folderId,
    mimeType: r.mimeType,
    sizeBytes: r.sizeBytes,
    sha256: r.sha256,
    storageKey: r.storageKey,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  ).toJson();

  static Note note(NoteRow r) => Note(
    id: r.id,
    title: r.title,
    body: r.body,
    folderId: r.folderId,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
    syncStatus: r.syncStatus,
  );

  static NotesCompanion noteCompanion(Note n) => NotesCompanion.insert(
    id: n.id,
    title: n.title,
    body: n.body,
    folderId: Value(n.folderId),
    version: Value(n.version),
    createdAt: n.createdAt,
    updatedAt: n.updatedAt,
    deletedAt: Value(n.deletedAt),
    syncStatus: Value(n.syncStatus),
  );

  static Map<String, Object?> notePayload(NoteRow r) => NoteDto(
    id: r.id,
    title: r.title,
    body: r.body,
    folderId: r.folderId,
    version: r.version,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
  ).toJson();

  static OutboxEntry outbox(OutboxRow r) => OutboxEntry(
    id: r.id,
    clientOpId: r.clientOpId,
    entityType: r.entityType,
    entityId: r.entityId,
    op: r.op,
    payload: r.payload,
    baseVersion: r.baseVersion,
    state: r.state,
    createdAt: r.createdAt,
    dependsOnTransfer: r.dependsOnTransfer,
    attemptCount: r.attemptCount,
    nextAttemptAt: r.nextAttemptAt,
    lastError: r.lastError,
  );

  static Conflict conflict(ConflictRow r) => Conflict(
    id: r.id,
    entityType: r.entityType,
    entityId: r.entityId,
    localSnapshot: r.localSnapshot,
    remoteSnapshot: r.remoteSnapshot,
    remoteVersion: r.remoteVersion,
    createdAt: r.createdAt,
    resolvedAt: r.resolvedAt,
    resolution: r.resolution,
  );
}
