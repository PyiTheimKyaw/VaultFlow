import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_ui/vf_ui.dart';

part 'vault_view_mode.g.dart';

enum VaultViewMode { list, grid }

/// List/grid toggle for the folder view, persisted in `app_settings`.
@Riverpod(keepAlive: true)
class VaultViewModeController extends _$VaultViewModeController {
  static const _key = 'vault_view_mode';

  @override
  VaultViewMode build() {
    ref.watch(databaseProvider).settingsDao.getSetting(_key).then((raw) {
      if (raw == VaultViewMode.grid.name) state = VaultViewMode.grid;
    }).ignore();
    return VaultViewMode.list;
  }

  void toggle() {
    state = state == VaultViewMode.list
        ? VaultViewMode.grid
        : VaultViewMode.list;
    ref
        .read(databaseProvider)
        .settingsDao
        .setSetting(_key, state.name)
        .ignore();
  }
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

/// Width of the persistent sidebar on expanded layouts, persisted.
@Riverpod(keepAlive: true)
class SidebarWidth extends _$SidebarWidth {
  static const _key = 'sidebar_width';
  static const double min = 200;
  static const double max = 480;

  @override
  double build() {
    ref.watch(databaseProvider).settingsDao.getSetting(_key).then((raw) {
      final stored = double.tryParse(raw ?? '');
      if (stored != null) state = stored.clamp(min, max);
    }).ignore();
    return VfSizes.sidebarWidth;
  }

  void set(double width) {
    state = width.clamp(min, max);
  }

  /// Persist once the drag ends rather than on every pixel.
  void commit() => ref
      .read(databaseProvider)
      .settingsDao
      .setSetting(_key, '$state')
      .ignore();
}
