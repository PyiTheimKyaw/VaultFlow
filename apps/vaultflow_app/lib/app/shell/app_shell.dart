import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/presentation/sync_status.dart';
import 'package:vaultflow_app/features/vault/application/share_intent.dart';
import 'package:vaultflow_app/features/vault/application/vault_view_mode.dart';
import 'package:vaultflow_app/features/vault/presentation/folder_tree.dart';
import 'package:vaultflow_app/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.path;
    final selectedFolder = folderIdFromPath(location);
    final labels = [
      l10n.navVault,
      l10n.navNotes,
      l10n.navTransfers,
      l10n.navSettings,
    ];
    final title = switch (location) {
      final l when l.startsWith(AppRoutes.settingsOutbox) =>
        l10n.titleSyncQueue,
      final l when l.startsWith(AppRoutes.settingsLock) => l10n.titleVaultLock,
      final l when l.startsWith(AppRoutes.settingsConflicts) =>
        l10n.titleConflicts,
      final l when l.startsWith(AppRoutes.search) => l10n.titleSearch,
      _ => labels[navigationShell.currentIndex],
    };
    // Files arriving from the OS share sheet are imported in the
    // background; surface the outcome wherever the user is.
    ref.listen(shareImportResultsProvider, (_, results) {
      if (results.isEmpty) return;
      reportImport(context, results);
      ref.read(shareImportResultsProvider.notifier).clear();
    });

    return AdaptiveScaffold(
      destinations: [
        for (var i = 0; i < appDestinations.length; i++)
          AdaptiveDestination(
            icon: appDestinations[i].icon,
            selectedIcon: appDestinations[i].selectedIcon,
            label: labels[i],
          ),
      ],
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _select,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!location.startsWith(AppRoutes.search))
            IconButton(
              key: const Key('search-button'),
              tooltip: l10n.searchTooltip,
              icon: const Icon(Icons.search),
              onPressed: () => context.go(AppRoutes.search),
            ),
          const Padding(
            padding: EdgeInsets.only(right: VfSpacing.md),
            child: SyncStatusButton(),
          ),
        ],
      ),
      sidebar: FolderTree(selectedFolderId: selectedFolder),
      sidebarWidth: ref.watch(sidebarWidthProvider),
      onSidebarResize: ref.read(sidebarWidthProvider.notifier).set,
      onSidebarResizeEnd: ref.read(sidebarWidthProvider.notifier).commit,
      body: navigationShell,
    );
  }

  /// `/vault/<id>` → `<id>`; anything else → `null` (root or not in vault).
  static String? folderIdFromPath(String path) {
    const prefix = '${AppRoutes.vault}/';
    if (!path.startsWith(prefix)) return null;
    final rest = path.substring(prefix.length);
    return rest.isEmpty ? null : Uri.decodeComponent(rest.split('/').first);
  }
}
