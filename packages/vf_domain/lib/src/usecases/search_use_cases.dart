import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/src/entities/folder_contents.dart';
import 'package:vf_domain/src/repositories/notes_repository.dart';
import 'package:vf_domain/src/repositories/vault_repository.dart';

/// Vault-wide search: folder and document names plus note full text.
class SearchUseCases {
  const SearchUseCases({required this.vault, required this.notes});

  final VaultRepository vault;
  final NotesRepository notes;

  /// Empty or blank queries return an empty result instead of everything.
  Future<Result<FolderContents>> search(String query, {int limit = 50}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Ok(FolderContents(folderId: null)));
    }
    return Result.guard(() async {
      final names = await vault.searchByName(trimmed, limit: limit);
      final matched = await notes.search(trimmed);
      return names.copyWith(notes: matched.take(limit).toList());
    }, onError: (e, st) => StorageFailure('$e', cause: e, stackTrace: st));
  }
}
