import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/vault/presentation/folder_tree.dart';
import 'package:vf_ui/vf_ui.dart';

/// Primary navigation destinations, in branch order of the router.
const appDestinations = [
  AdaptiveDestination(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: 'Vault',
  ),
  AdaptiveDestination(
    icon: Icons.sticky_note_2_outlined,
    selectedIcon: Icons.sticky_note_2,
    label: 'Notes',
  ),
  AdaptiveDestination(
    icon: Icons.swap_vert_outlined,
    selectedIcon: Icons.swap_vert,
    label: 'Transfers',
  ),
  AdaptiveDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

/// Wraps every signed-in page in the [AdaptiveScaffold].
///
/// Each destination is a [StatefulShellBranch], so switching tabs preserves
/// the navigation stack (and scroll position) of the branch you left.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Tapping the active destination again pops back to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queued = ref.watch(outboxCountProvider).value ?? 0;
    final location = GoRouterState.of(context).uri.path;
    final selectedFolder = _folderIdFrom(location);
    final title = switch (location) {
      final l when l.startsWith(AppRoutes.settingsOutbox) => 'Sync queue',
      _ => appDestinations[navigationShell.currentIndex].label,
    };

    return AdaptiveScaffold(
      destinations: appDestinations,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _select,
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VfSpacing.md),
            child: SyncStatusBadge(
              key: const Key('shell-sync-badge'),
              status: queued == 0
                  ? SyncBadgeStatus.synced
                  : SyncBadgeStatus.pending,
              onTap: () => context.go(AppRoutes.settingsOutbox),
            ),
          ),
        ],
      ),
      sidebar: FolderTree(selectedFolderId: selectedFolder),
      body: navigationShell,
    );
  }

  /// `/vault/<id>` → `<id>`; anything else → `null` (root or not in vault).
  static String? _folderIdFrom(String path) {
    const prefix = '${AppRoutes.vault}/';
    if (!path.startsWith(prefix)) return null;
    final rest = path.substring(prefix.length);
    return rest.isEmpty ? null : Uri.decodeComponent(rest.split('/').first);
  }
}
