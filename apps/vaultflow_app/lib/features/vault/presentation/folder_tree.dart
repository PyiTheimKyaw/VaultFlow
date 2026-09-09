import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/vault/application/vault_view_mode.dart';
import 'package:vaultflow_app/features/vault/presentation/drag_drop.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_item_tile.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Sidebar folder tree. Tapping a row navigates; the chevron expands.
class FolderTree extends ConsumerWidget {
  const FolderTree({super.key, this.selectedFolderId});

  /// Folder currently shown in the content pane (`null` = root).
  final String? selectedFolderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(allFoldersProvider).value ?? const [];
    final expanded = ref.watch(expandedFoldersProvider);
    final byParent = <String?, List<Folder>>{};
    for (final f in folders) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }

    final rows = <Widget>[
      FolderDropTarget(
        folderId: null,
        builder: (context, hovering) => _Row(
          key: const Key('tree-root'),
          icon: Icons.home_outlined,
          label: 'All files',
          depth: 0,
          selected: selectedFolderId == null,
          highlighted: hovering,
          onTap: () => context.go(AppRoutes.vault),
        ),
      ),
    ];

    void visit(String? parent, int depth) {
      for (final f in byParent[parent] ?? const <Folder>[]) {
        final hasChildren = byParent.containsKey(f.id);
        final isOpen = expanded.contains(f.id);
        rows.add(
          FolderDropTarget(
            folderId: f.id,
            builder: (context, hovering) => _Row(
              key: Key('tree-${f.id}'),
              icon: isOpen ? Icons.folder_open_outlined : Icons.folder_outlined,
              label: f.name,
              depth: depth + 1,
              selected: selectedFolderId == f.id,
              highlighted: hovering,
              expandable: hasChildren,
              expanded: isOpen,
              onToggle: () =>
                  ref.read(expandedFoldersProvider.notifier).toggle(f.id),
              onTap: () => context.go(AppRoutes.folder(f.id)),
              onContextMenu: (position) => VaultItemActions(
                context,
                ref,
                VaultItem.folder(f),
              ).showContextMenu(position),
            ),
          ),
        );
        if (hasChildren && isOpen) visit(f.id, depth + 1);
      }
    }

    visit(null, 0);

    return ListView(
      key: const Key('sidebar'),
      padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
      children: rows,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.depth,
    required this.selected,
    required this.onTap,
    super.key,
    this.highlighted = false,
    this.expandable = false,
    this.expanded = false,
    this.onToggle,
    this.onContextMenu,
  });

  /// True while a drag hovers over this row.
  final bool highlighted;
  final ValueChanged<Offset>? onContextMenu;

  final IconData icon;
  final String label;
  final int depth;
  final bool selected;
  final bool expandable;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onSecondaryTapUp: onContextMenu == null
          ? null
          : (d) => onContextMenu!(d.globalPosition),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
        tileColor: highlighted ? scheme.tertiaryContainer : null,
        contentPadding: EdgeInsets.only(
          left: VfSpacing.sm + depth * VfSpacing.lg,
          right: VfSpacing.sm,
        ),
        leading: SizedBox(
          width: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expandable)
                Semantics(
                  button: true,
                  label: expanded ? 'Collapse $label' : 'Expand $label',
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(VfRadius.sm),
                    child: Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: VfSpacing.xs),
              Icon(icon, size: 20),
            ],
          ),
        ),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}
