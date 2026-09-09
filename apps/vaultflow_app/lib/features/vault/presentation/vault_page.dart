import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vaultflow_app/features/vault/application/vault_selection.dart';
import 'package:vaultflow_app/features/vault/application/vault_view_mode.dart';
import 'package:vaultflow_app/features/vault/presentation/dialogs.dart';
import 'package:vaultflow_app/features/vault/presentation/drag_drop.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_item_tile.dart';
import 'package:vaultflow_app/l10n/generated/app_localizations.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Folder contents. `null` [folderId] is the vault root.
///
/// Also the home of the vault's keyboard shortcuts and OS file drops, so
/// they apply to the folder being viewed.
class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key, this.folderId});

  final String? folderId;

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> {
  bool _osDragHover = false;

  /// Root of the page's focus scope so shortcuts work as soon as the page
  /// shows, without the user having to click into it first.
  final _focus = FocusNode(debugLabel: 'vault-page');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _ensureFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    // Navigating pushes a new page: never inherit the previous selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(vaultSelectionProvider.notifier).clear();
    });
  }

  @override
  void didUpdateWidget(VaultPage old) {
    super.didUpdateWidget(old);
    if (old.folderId != widget.folderId) {
      ref.read(vaultSelectionProvider.notifier).clear();
    }
  }

  Future<void> _importDropped(List<DropItem> files) async {
    if (files.isEmpty) return;
    final results = await ref.read(documentImporterProvider).importAll([
      for (final f in files) ImportSource(name: f.name, bytes: f.openRead()),
    ], folderId: widget.folderId);
    if (!mounted) return;
    reportImport(context, results);
  }

  Future<void> _deleteSelection() async {
    final selected = ref.read(vaultSelectionProvider).values.toList();
    if (selected.isEmpty) return;
    final confirmed = await showDeleteDialog(
      context,
      itemName: selected.length == 1
          ? selected.single.name
          : '${selected.length} items',
      isFolder: selected.any((r) => r.type == EntityType.folder),
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(vaultBatchActionsProvider).delete(selected);
    ref.read(vaultSelectionProvider.notifier).clear();
    if (mounted) reportBatch(context, result, verb: 'Deleted');
  }

  Future<void> _moveSelection() async {
    final selected = ref.read(vaultSelectionProvider).values.toList();
    if (selected.isEmpty) return;
    final target = await showMoveDialog(
      context,
      title: selected.length == 1
          ? 'Move "${selected.single.name}" to…'
          : 'Move ${selected.length} items to…',
      excluded: {
        for (final r in selected)
          if (r.type == EntityType.folder) r.id,
      },
    );
    if (target == null || !mounted) return;
    final result = await ref
        .read(vaultBatchActionsProvider)
        .move(selected, target.folderId);
    ref.read(vaultSelectionProvider.notifier).clear();
    if (mounted) reportBatch(context, result, verb: 'Moved');
  }

  void _selectAll(FolderContents? contents) {
    if (contents == null) return;
    ref.read(vaultSelectionProvider.notifier).selectAll([
      for (final f in contents.folders) VaultItem.folder(f).asRef,
      for (final d in contents.documents) VaultItem.document(d).asRef,
      for (final n in contents.notes) VaultItem.note(n).asRef,
    ]);
  }

  Future<void> _renameSelection(FolderContents? contents) async {
    final selected = ref.read(vaultSelectionProvider).values.toList();
    if (selected.length != 1 || contents == null) return;
    final item = _itemFor(contents, selected.single.id);
    if (item == null) return;
    await VaultItemActions(context, ref, item).rename();
  }

  static VaultItem? _itemFor(FolderContents c, String id) {
    for (final f in c.folders) {
      if (f.id == id) return VaultItem.folder(f);
    }
    for (final d in c.documents) {
      if (d.id == id) return VaultItem.document(d);
    }
    for (final n in c.notes) {
      if (n.id == id) return VaultItem.note(n);
    }
    return null;
  }

  static List<SingleActivator> _cmd(
    LogicalKeyboardKey key, {
    bool shift = false,
  }) => VaultCommands.cmd(key, shift: shift);

  /// Selection shortcuts live here; the creation shortcuts (⌘N, ⌘⇧N, ⌘I,
  /// ⌘F) are app-wide and registered by the shell.
  Map<ShortcutActivator, VoidCallback> _shortcuts(FolderContents? contents) {
    final selecting = ref.read(vaultSelectionProvider).isNotEmpty;
    return {
      for (final a in _cmd(LogicalKeyboardKey.keyA))
        a: () => _selectAll(contents),
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          ref.read(vaultSelectionProvider.notifier).clear(),
      const SingleActivator(LogicalKeyboardKey.f2): () =>
          unawaited(_renameSelection(contents)),
      if (selecting) ...{
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            unawaited(_deleteSelection()),
        const SingleActivator(LogicalKeyboardKey.backspace, meta: true): () =>
            unawaited(_deleteSelection()),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final folderId = widget.folderId;
    final contents = ref.watch(folderContentsProvider(folderId));
    final folder = folderId == null
        ? const AsyncData<Folder?>(null)
        : ref.watch(folderProvider(folderId));
    final viewMode = ref.watch(vaultViewModeControllerProvider);
    final selection = ref.watch(vaultSelectionProvider);
    final toolbar = _Toolbar(folderId: folderId, viewMode: viewMode);

    if (folderId != null && folder.hasValue && folder.value == null) {
      return EmptyState(
        key: const Key('vault-missing'),
        icon: Icons.folder_off_outlined,
        title: 'Folder not found',
        message: 'It may have been deleted on another device.',
        action: FilledButton.tonal(
          onPressed: () => context.go(AppRoutes.vault),
          child: const Text('Back to vault'),
        ),
      );
    }

    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selection.isEmpty)
          toolbar
        else
          _SelectionBar(
            count: selection.length,
            onSelectAll: () => _selectAll(contents.value),
            onMove: _moveSelection,
            onDelete: _deleteSelection,
            onClear: ref.read(vaultSelectionProvider.notifier).clear,
          ),
        const Divider(),
        Expanded(
          child: contents.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load folder',
              message: '$e',
            ),
            data: (data) => _Refreshable(
              child: data.isEmpty
                  ? EmptyState(
                      key: Key('vault-${folderId ?? 'root'}-empty'),
                      icon: Icons.folder_open_outlined,
                      title: folderId == null
                          ? 'Your vault is empty'
                          : 'This folder is empty',
                      message:
                          'Create a folder, write a note, or import files. '
                          'Everything works offline and syncs later.',
                    )
                  : _ContentsView(
                      key: Key('vault-${folderId ?? 'root'}'),
                      contents: data,
                      viewMode: viewMode,
                    ),
            ),
          ),
        ),
      ],
    );

    _ensureFocus();
    return FocusTraversalGroup(
      child: CallbackShortcuts(
        bindings: _shortcuts(contents.value),
        child: Focus(
          focusNode: _focus,
          child: DropTarget(
            enable: usesMouseDrag,
            onDragEntered: (_) => setState(() => _osDragHover = true),
            onDragExited: (_) => setState(() => _osDragHover = false),
            onDragDone: (d) {
              setState(() => _osDragHover = false);
              unawaited(_importDropped(d.files));
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                page,
                if (_osDragHover)
                  IgnorePointer(
                    child: Container(
                      key: const Key('vault-drop-overlay'),
                      margin: const EdgeInsets.all(VfSpacing.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(VfRadius.lg),
                      ),
                      child: const Center(
                        child: Text(
                          'Drop files to import here',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pull-to-refresh runs a sync round on touch platforms; on desktop and
/// web the app bar's sync button does the same thing.
class _Refreshable extends ConsumerWidget {
  const _Refreshable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usesMouseDrag) return child;
    return RefreshIndicator(
      onRefresh: () => ref.read(syncCoordinatorProvider.notifier).syncNow(),
      child: child is ScrollView
          ? child
          : LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: c.maxHeight, child: child),
              ),
            ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onSelectAll,
    required this.onMove,
    required this.onDelete,
    required this.onClear,
  });

  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VfSpacing.sm,
        vertical: VfSpacing.xs,
      ),
      child: Row(
        key: const Key('selection-bar'),
        children: [
          IconButton(
            key: const Key('selection-clear'),
            tooltip: 'Clear selection (Esc)',
            icon: const Icon(Icons.close),
            onPressed: onClear,
          ),
          Text(
            AppLocalizations.of(context).selectedCount(count),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          TextButton.icon(
            key: const Key('selection-all'),
            onPressed: onSelectAll,
            icon: const Icon(Icons.select_all),
            label: const Text('All'),
          ),
          TextButton.icon(
            key: const Key('selection-move'),
            onPressed: onMove,
            icon: const Icon(Icons.drive_file_move_outline),
            label: const Text('Move'),
          ),
          TextButton.icon(
            key: const Key('selection-delete'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Create/import actions for the folder being viewed, shared by the
/// toolbar, the keyboard shortcuts and the app shell.
class VaultCommands {
  const VaultCommands(this.context, this.ref, this.folderId);

  final BuildContext context;
  final WidgetRef ref;
  final String? folderId;

  /// ⌘ on macOS, Ctrl elsewhere; both are registered so the same table
  /// works everywhere.
  static List<SingleActivator> cmd(
    LogicalKeyboardKey key, {
    bool shift = false,
  }) => [
    SingleActivator(key, meta: true, shift: shift),
    SingleActivator(key, control: true, shift: shift),
  ];

  Future<void> newFolder() async {
    final name = await showNameDialog(
      context,
      title: 'New folder',
      confirmLabel: 'Create',
    );
    if (name == null || !context.mounted) return;
    final result = await ref
        .read(vaultUseCasesProvider)
        .createFolder(name: name, parentId: folderId);
    if (context.mounted) reportResult(context, result);
  }

  Future<void> newNote() async {
    final result = await ref
        .read(notesUseCasesProvider)
        .create(folderId: folderId);
    if (!context.mounted) return;
    if (reportResult(context, result)) {
      context.go(AppRoutes.note(result.getOrThrow().id));
    }
  }

  Future<void> import() async {
    final results = await ref
        .read(documentImporterProvider)
        .pickAndImport(folderId: folderId);
    if (!context.mounted || results.isEmpty) return;
    reportImport(context, results);
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.folderId, required this.viewMode});

  final String? folderId;
  final VaultViewMode viewMode;

  /// Below this content width the three actions collapse into a menu.
  static const double _fullToolbarMinWidth = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _fullToolbarMinWidth;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            VfSpacing.sm,
            VfSpacing.xs,
            VfSpacing.sm,
            VfSpacing.xs,
          ),
          child: _buildRow(context, ref, compact: compact),
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref, {
    required bool compact,
  }) {
    return Row(
      children: [
        Expanded(child: _Breadcrumb(folderId: folderId)),
        IconButton(
          key: const Key('toggle-view'),
          tooltip: viewMode == VaultViewMode.list ? 'Grid view' : 'List view',
          icon: Icon(
            viewMode == VaultViewMode.list
                ? Icons.grid_view_outlined
                : Icons.view_list_outlined,
          ),
          onPressed: () =>
              ref.read(vaultViewModeControllerProvider.notifier).toggle(),
        ),
        if (compact)
          MenuAnchor(
            builder: (context, controller, _) => IconButton(
              key: const Key('vault-add-menu'),
              tooltip: 'Add',
              icon: const Icon(Icons.add),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
            menuChildren: [
              MenuItemButton(
                key: const Key('vault-new-folder'),
                leadingIcon: const Icon(Icons.create_new_folder_outlined),
                onPressed: () =>
                    VaultCommands(context, ref, folderId).newFolder(),
                child: const Text('New folder'),
              ),
              MenuItemButton(
                key: const Key('vault-new-note'),
                leadingIcon: const Icon(Icons.note_add_outlined),
                onPressed: () =>
                    VaultCommands(context, ref, folderId).newNote(),
                child: const Text('New note'),
              ),
              MenuItemButton(
                key: const Key('vault-import'),
                leadingIcon: const Icon(Icons.upload_file_outlined),
                onPressed: () => VaultCommands(context, ref, folderId).import(),
                child: const Text('Import files'),
              ),
            ],
          )
        else ...[
          TextButton.icon(
            key: const Key('vault-new-folder'),
            onPressed: () => VaultCommands(context, ref, folderId).newFolder(),
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('New folder'),
          ),
          TextButton.icon(
            key: const Key('vault-new-note'),
            onPressed: () => VaultCommands(context, ref, folderId).newNote(),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('New note'),
          ),
          FilledButton.tonalIcon(
            key: const Key('vault-import'),
            onPressed: () => VaultCommands(context, ref, folderId).import(),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import'),
          ),
        ],
      ],
    );
  }
}

class _Breadcrumb extends ConsumerWidget {
  const _Breadcrumb({required this.folderId});

  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chain = ref.watch(breadcrumbProvider(folderId));
    final theme = Theme.of(context);
    final separator = Icon(
      Icons.chevron_right,
      size: 18,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SingleChildScrollView(
      key: const Key('breadcrumb'),
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          FolderDropTarget(
            folderId: null,
            builder: (context, hovering) => TextButton(
              style: hovering ? _hoverStyle(theme) : null,
              onPressed: folderId == null
                  ? null
                  : () => context.go(AppRoutes.vault),
              child: const Text('Vault'),
            ),
          ),
          for (var i = 0; i < chain.length; i++) ...[
            separator,
            if (i == chain.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VfSpacing.sm),
                child: Text(chain[i].name, style: theme.textTheme.labelLarge),
              )
            else
              FolderDropTarget(
                folderId: chain[i].id,
                builder: (context, hovering) => TextButton(
                  style: hovering ? _hoverStyle(theme) : null,
                  onPressed: () => context.go(AppRoutes.folder(chain[i].id)),
                  child: Text(chain[i].name),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

ButtonStyle _hoverStyle(ThemeData theme) =>
    TextButton.styleFrom(backgroundColor: theme.colorScheme.tertiaryContainer);

class _ContentsView extends ConsumerWidget {
  const _ContentsView({
    required this.contents,
    required this.viewMode,
    super.key,
  });

  final FolderContents contents;
  final VaultViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Items removed elsewhere (sync, another device) leave the selection.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultSelectionProvider.notifier).retain([
        for (final f in contents.folders) f.id,
        for (final d in contents.documents) d.id,
        for (final n in contents.notes) n.id,
      ]);
    });
    final items = <VaultItem>[
      for (final f in contents.folders) VaultItem.folder(f),
      for (final d in contents.documents) VaultItem.document(d),
      for (final n in contents.notes) VaultItem.note(n),
    ];
    if (viewMode == VaultViewMode.grid) {
      return GridView.builder(
        padding: VfSpacing.pagePadding,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: VfSpacing.md,
          crossAxisSpacing: VfSpacing.md,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => VaultItemCard(item: items[i]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 72),
      itemBuilder: (context, i) => VaultItemTile(item: items[i]),
    );
  }
}
