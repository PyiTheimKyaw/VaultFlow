import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/src/entities/document.dart';
import 'package:vf_domain/src/entities/folder.dart';
import 'package:vf_domain/src/entities/sync_status.dart';
import 'package:vf_domain/src/repositories/vault_repository.dart';
import 'package:vf_domain/src/usecases/item_name.dart';
import 'package:vf_protocol/vf_protocol.dart' show EntityType;

/// Bundles the collaborators every vault use case needs.
final class VaultUseCases {
  const VaultUseCases({
    required this.vault,
    this.clock = const SystemClock(),
    this.newId = VfId.next,
  });

  final VaultRepository vault;
  final Clock clock;
  final String Function() newId;

  Future<Result<Folder>> createFolder({
    required String name,
    String? parentId,
  }) async {
    final validName = ItemName.validate(name);
    if (validName case Err(:final failure)) return Err(failure);

    if (parentId != null && await vault.getFolder(parentId) == null) {
      return const Err(NotFoundFailure('Parent folder not found'));
    }
    final now = clock.now();
    final folder = Folder(
      id: newId(),
      name: validName.getOrThrow(),
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    return await Result.guard(() async {
      await vault.createFolder(folder);
      return folder;
    }, onError: _storage);
  }

  Future<Result<void>> rename({
    required EntityType type,
    required String id,
    required String name,
  }) async {
    final validName = ItemName.validate(name);
    if (validName case Err(:final failure)) return Err(failure);
    final now = clock.now();
    return await Result.guard(() async {
      switch (type) {
        case EntityType.folder:
          await vault.renameFolder(id, validName.getOrThrow(), now);
        case EntityType.document:
          await vault.renameDocument(id, validName.getOrThrow(), now);
        case EntityType.note:
          throw const ValidationFailure('Use NotesUseCases to rename notes');
      }
    }, onError: _storage);
  }

  /// Moves a folder or document under [targetFolderId] (`null` = root).
  ///
  /// Refuses to move a folder into itself or one of its descendants.
  Future<Result<void>> move({
    required EntityType type,
    required String id,
    required String? targetFolderId,
  }) async {
    if (targetFolderId != null &&
        await vault.getFolder(targetFolderId) == null) {
      return const Err(NotFoundFailure('Target folder not found'));
    }
    if (type == EntityType.folder && targetFolderId != null) {
      if (targetFolderId == id) {
        return const Err(ValidationFailure('Cannot move a folder into itself'));
      }
      final ancestors = await vault.getAncestors(targetFolderId);
      if (ancestors.any((f) => f.id == id)) {
        return const Err(
          ValidationFailure('Cannot move a folder into its own subfolder'),
        );
      }
    }
    final now = clock.now();
    return await Result.guard(() async {
      switch (type) {
        case EntityType.folder:
          await vault.moveFolder(id, targetFolderId, now);
        case EntityType.document:
          await vault.moveDocument(id, targetFolderId, now);
        case EntityType.note:
          throw const ValidationFailure('Use NotesUseCases to move notes');
      }
    }, onError: _storage);
  }

  Future<Result<void>> delete({required EntityType type, required String id}) {
    final now = clock.now();
    return Result.guard(() async {
      switch (type) {
        case EntityType.folder:
          await vault.deleteFolder(id, now);
        case EntityType.document:
          await vault.deleteDocument(id, now);
        case EntityType.note:
          throw const ValidationFailure('Use NotesUseCases to delete notes');
      }
    }, onError: _storage);
  }

  /// Registers a file that has already been copied into the local cache.
  Future<Result<Document>> importDocument({
    required String name,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    String? folderId,
    String? localPath,

    /// Upload session the document's sync op waits for.
    String? dependsOnTransfer,
  }) async {
    final validName = ItemName.validate(name);
    if (validName case Err(:final failure)) return Err(failure);
    if (sizeBytes < 0) {
      return const Err(ValidationFailure('Size cannot be negative'));
    }
    if (folderId != null && await vault.getFolder(folderId) == null) {
      return const Err(NotFoundFailure('Folder not found'));
    }
    final now = clock.now();
    final document = Document(
      id: newId(),
      name: validName.getOrThrow(),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      sha256: sha256,
      folderId: folderId,
      localPath: localPath,
      cacheState: localPath == null ? CacheState.none : CacheState.complete,
      createdAt: now,
      updatedAt: now,
    );
    return await Result.guard(() async {
      await vault.createDocument(
        document,
        dependsOnTransfer: dependsOnTransfer,
      );
      return document;
    }, onError: _storage);
  }

  static Failure _storage(Object error, StackTrace stackTrace) =>
      StorageFailure(error.toString(), cause: error, stackTrace: stackTrace);
}
