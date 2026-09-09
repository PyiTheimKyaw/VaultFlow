import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

part 'vault_selection.g.dart';

/// One selectable/movable thing in a folder listing.
typedef VaultRef = ({EntityType type, String id, String name});

/// Multi-select state for the folder view, keyed by id. Cleared on
/// navigation.
@riverpod
class VaultSelection extends _$VaultSelection {
  @override
  Map<String, VaultRef> build() => const {};

  void toggle(VaultRef item) => state = state.containsKey(item.id)
      ? ({...state}..remove(item.id))
      : {...state, item.id: item};

  void selectAll(Iterable<VaultRef> items) =>
      state = {for (final i in items) i.id: i};

  void clear() => state = const {};

  /// Drops ids that no longer exist in the listing.
  void retain(Iterable<String> present) {
    final keep = present.toSet();
    if (state.keys.any((id) => !keep.contains(id))) {
      state = {
        for (final e in state.entries)
          if (keep.contains(e.key)) e.key: e.value,
      };
    }
  }
}

/// Batch operations over folders, documents and notes. Each item is moved
/// or deleted through its own use case; the first failure is reported and
/// the rest still run so a partial batch never silently stops.
class VaultBatchActions {
  const VaultBatchActions({required this.vault, required this.notes});

  final VaultUseCases vault;
  final NotesUseCases notes;

  Future<Result<int>> move(Iterable<VaultRef> items, String? targetFolderId) =>
      _each(
        items,
        (item) => switch (item.type) {
          EntityType.note => notes.move(
            id: item.id,
            targetFolderId: targetFolderId,
          ),
          _ => vault.move(
            type: item.type,
            id: item.id,
            targetFolderId: targetFolderId,
          ),
        },
      );

  Future<Result<int>> delete(Iterable<VaultRef> items) => _each(
    items,
    (item) => switch (item.type) {
      EntityType.note => notes.delete(item.id),
      _ => vault.delete(type: item.type, id: item.id),
    },
  );

  Future<Result<int>> _each(
    Iterable<VaultRef> items,
    Future<Result<void>> Function(VaultRef item) op,
  ) async {
    Failure? first;
    var done = 0;
    for (final item in items) {
      switch (await op(item)) {
        case Ok():
          done++;
        case Err(:final failure):
          first ??= failure;
      }
    }
    return first == null ? Ok(done) : Err(first);
  }
}

@Riverpod(keepAlive: true)
VaultBatchActions vaultBatchActions(Ref ref) => VaultBatchActions(
  vault: ref.watch(vaultUseCasesProvider),
  notes: ref.watch(notesUseCasesProvider),
);
