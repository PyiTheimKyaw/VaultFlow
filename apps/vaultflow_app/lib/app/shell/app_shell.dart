import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/routes.dart';
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
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Tapping the active destination again pops back to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: appDestinations,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _select,
      appBar: AppBar(
        title: Text(appDestinations[navigationShell.currentIndex].label),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: VfSpacing.md),
            child: SyncStatusBadge(status: SyncBadgeStatus.synced),
          ),
        ],
      ),
      sidebar: const _SidebarPlaceholder(),
      body: navigationShell,
    );
  }
}

/// Stand-in for the folder tree that arrives with Phase 2.
class _SidebarPlaceholder extends StatelessWidget {
  const _SidebarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('sidebar'),
      padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('All files'),
          onTap: () => context.go(AppRoutes.vault),
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Sample folder'),
          onTap: () => context.go(AppRoutes.folder('sample')),
        ),
        const ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Trash'),
          enabled: false,
        ),
      ],
    );
  }
}
