import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Applies the user's choice for a recorded conflict.
///
/// * keep remote: the server snapshot replaces the local row.
/// * keep local: the local row is re-based on the remote version and pushed
///   again as an update.
/// * keep both: the server snapshot replaces the local row and the local
///   edit is preserved as a new "Conflicted copy" entity.
class ConflictResolver {
  ConflictResolver({
    required VaultFlowDatabase db,
    required this.deviceLabel,
    this.clock = const SystemClock(),
    String Function()? newId,
  }) : _db = db,
       _repo = DriftSyncRepository(db),
       _vault = DriftVaultRepository(db),
       _notes = DriftNotesRepository(db),
       _newId = newId ?? VfId.next;

  final VaultFlowDatabase _db;
  final DriftSyncRepository _repo;
  final DriftVaultRepository _vault;
  final DriftNotesRepository _notes;
  final String deviceLabel;
  final Clock clock;
  final String Function() _newId;

  Future<Result<void>> resolve(
    String conflictId,
    ConflictResolution choice,
  ) async {
    final conflict = await _repo.getConflict(conflictId);
    if (conflict == null || conflict.isResolved) {
      return const Err(NotFoundFailure('Conflict not found'));
    }
    return await Result.guard(() async {
      switch (choice) {
        case ConflictResolution.keepRemote:
          await _applyRemote(conflict);
        case ConflictResolution.keepLocal:
          await _keepLocal(conflict);
        case ConflictResolution.keepBoth:
          final local = await _repo.localSnapshot(
            conflict.entityType,
            conflict.entityId,
          );
          await _applyRemote(conflict);
          if (local != null) await _createCopy(conflict.entityType, local);
      }
      await _db.conflictsDao.resolve(conflictId, choice, clock.now());
    }, onError: (e, s) => StorageFailure('$e', cause: e, stackTrace: s));
  }

  Future<void> _applyRemote(Conflict conflict) async {
    if (conflict.remoteSnapshot.isEmpty) {
      // The server never had this entity: nothing to take from it.
      await _repo.markSynced(conflict.entityType, conflict.entityId);
      return;
    }
    await _repo.applyRemoteSnapshot(
      conflict.entityType,
      conflict.remoteSnapshot,
      version: conflict.remoteVersion,
    );
  }

  Future<void> _keepLocal(Conflict conflict) => _db.transaction(() async {
    final type = conflict.entityType;
    final id = conflict.entityId;
    // Re-base on the server version so the next push is accepted.
    await _repo.markSynced(type, id, version: conflict.remoteVersion);
    final snapshot = await _repo.localSnapshot(type, id);
    if (snapshot == null) return;
    await _db.outboxDao.enqueue(
      entityType: type,
      entityId: id,
      op: conflict.remoteVersion == 0 ? SyncOp.create : SyncOp.update,
      payload: snapshot,
      baseVersion: conflict.remoteVersion,
      now: clock.now(),
    );
    await _repo.markPending(type, id);
  });

  Future<void> _createCopy(EntityType type, Map<String, Object?> local) async {
    final now = clock.now();
    final suffix = ' (Conflicted copy, $deviceLabel, ${_date(now)})';
    switch (type) {
      case EntityType.folder:
        final dto = FolderDto.fromJson({...local, 'version': 0});
        await _vault.createFolder(
          Folder(
            id: _newId(),
            name: '${dto.name}$suffix',
            parentId: dto.parentId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      case EntityType.document:
        final dto = DocumentDto.fromJson({...local, 'version': 0});
        final current = await _db.documentsDao.getById(dto.id);
        await _vault.createDocument(
          Document(
            id: _newId(),
            name: _withSuffix(dto.name, suffix),
            folderId: dto.folderId,
            mimeType: dto.mimeType,
            sizeBytes: dto.sizeBytes,
            sha256: dto.sha256,
            localPath: current?.localPath,
            cacheState: current?.cacheState ?? CacheState.none,
            createdAt: now,
            updatedAt: now,
          ),
        );
      case EntityType.note:
        final dto = NoteDto.fromJson({...local, 'version': 0});
        await _notes.createNote(
          Note(
            id: _newId(),
            title: '${dto.title.isEmpty ? 'Untitled note' : dto.title}$suffix',
            body: dto.body,
            folderId: dto.folderId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    }
  }

  /// `report (Conflicted copy, …).pdf` keeps the extension usable.
  static String _withSuffix(String fileName, String suffix) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return '$fileName$suffix';
    return '${fileName.substring(0, dot)}$suffix${fileName.substring(dot)}';
  }

  static String _date(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}
