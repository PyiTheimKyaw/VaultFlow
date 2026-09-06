import 'package:vf_domain/src/entities/document.dart';
import 'package:vf_domain/src/entities/folder.dart';
import 'package:vf_domain/src/entities/folder_contents.dart';
import 'package:vf_domain/src/entities/sync_status.dart';

/// Folders and documents. Every mutation writes the entity row *and* the
/// matching outbox row in one transaction; callers never touch the outbox.
///
/// Implementations throw `StorageFailure` on database errors; use cases wrap
/// calls with `Result.guard`.
abstract interface class VaultRepository {
  /// All live folders, for the sidebar tree and move pickers.
  Stream<List<Folder>> watchAllFolders();

  Stream<Folder?> watchFolder(String id);

  Future<Folder?> getFolder(String id);

  /// Root-first chain of ancestors ending with [folderId] itself.
  Future<List<Folder>> getAncestors(String folderId);

  /// Live children of [folderId] (`null` for the root), sorted by name.
  Stream<FolderContents> watchContents(String? folderId);

  Future<Document?> getDocument(String id);

  Stream<Document?> watchDocument(String id);

  Future<void> createFolder(Folder folder);

  Future<void> renameFolder(String id, String name, DateTime now);

  Future<void> moveFolder(String id, String? parentId, DateTime now);

  /// Soft-deletes the folder and everything beneath it.
  Future<void> deleteFolder(String id, DateTime now);

  Future<void> createDocument(Document document);

  Future<void> renameDocument(String id, String name, DateTime now);

  Future<void> moveDocument(String id, String? folderId, DateTime now);

  Future<void> deleteDocument(String id, DateTime now);

  /// Updates the local cache bookkeeping only; not synced.
  Future<void> updateDocumentCache(
    String id, {
    required CacheState cacheState,
    String? localPath,
  });
}
