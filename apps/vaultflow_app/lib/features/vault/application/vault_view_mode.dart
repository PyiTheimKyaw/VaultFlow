import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_view_mode.g.dart';

enum VaultViewMode { list, grid }

/// List/grid toggle for the folder view. In-memory for now; Phase 6 persists
/// it in `app_settings`.
@riverpod
class VaultViewModeController extends _$VaultViewModeController {
  @override
  VaultViewMode build() => VaultViewMode.list;

  void toggle() => state = state == VaultViewMode.list
      ? VaultViewMode.grid
      : VaultViewMode.list;
}

/// Which folders are expanded in the sidebar tree.
@riverpod
class ExpandedFolders extends _$ExpandedFolders {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void expandAll(Iterable<String> ids) => state = {...state, ...ids};
}
