import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vaultflow_app/features/vault/application/vault_view_mode.dart';
import 'package:vaultflow_app/features/vault/presentation/dialogs.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_item_tile.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Folder contents. `null` [folderId] is the vault root.
class VaultPage extends ConsumerWidget {
  const VaultPage({super.key, this.folderId});

  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(folderContentsProvider(folderId));
    final folder = folderId == null
        ? const AsyncData<Folder?>(null)
        : ref.watch(folderProvider(folderId!));
    final viewMode = ref.watch(vaultViewModeControllerProvider);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(folderId: folderId, viewMode: viewMode),
        const Divider(),
        Expanded(
          child: contents.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load folder',
              message: '$e',
            ),
            data: (data) => data.isEmpty
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
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.folderId, required this.viewMode});

  final String? folderId;
  final VaultViewMode viewMode;

  Future<void> _newFolder(BuildContext context, WidgetRef ref) async {
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

  Future<void> _newNote(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(notesUseCasesProvider)
        .create(folderId: folderId);
    if (!context.mounted) return;
    if (reportResult(context, result)) {
      context.go(AppRoutes.note(result.getOrThrow().id));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final results = await ref
        .read(documentImporterProvider)
        .pickAndImport(folderId: folderId);
    if (!context.mounted || results.isEmpty) return;
    final failures = results.where((r) => r.isErr).toList();
    if (failures.isEmpty) {
      reportResult(
        context,
        okVoid,
        successMessage: results.length == 1
            ? 'Imported ${results.single.getOrThrow().name}'
            : 'Imported ${results.length} files',
      );
    } else {
      reportResult(context, failures.first);
    }
  }

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
                onPressed: () => _newFolder(context, ref),
                child: const Text('New folder'),
              ),
              MenuItemButton(
                key: const Key('vault-new-note'),
                leadingIcon: const Icon(Icons.note_add_outlined),
                onPressed: () => _newNote(context, ref),
                child: const Text('New note'),
              ),
              MenuItemButton(
                key: const Key('vault-import'),
                leadingIcon: const Icon(Icons.upload_file_outlined),
                onPressed: () => _import(context, ref),
                child: const Text('Import files'),
              ),
            ],
          )
        else ...[
          TextButton.icon(
            key: const Key('vault-new-folder'),
            onPressed: () => _newFolder(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('New folder'),
          ),
          TextButton.icon(
            key: const Key('vault-new-note'),
            onPressed: () => _newNote(context, ref),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('New note'),
          ),
          FilledButton.tonalIcon(
            key: const Key('vault-import'),
            onPressed: () => _import(context, ref),
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
          TextButton(
            onPressed: folderId == null
                ? null
                : () => context.go(AppRoutes.vault),
            child: const Text('Vault'),
          ),
          for (var i = 0; i < chain.length; i++) ...[
            separator,
            if (i == chain.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VfSpacing.sm),
                child: Text(chain[i].name, style: theme.textTheme.labelLarge),
              )
            else
              TextButton(
                onPressed: () => context.go(AppRoutes.folder(chain[i].id)),
                child: Text(chain[i].name),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContentsView extends StatelessWidget {
  const _ContentsView({
    required this.contents,
    required this.viewMode,
    super.key,
  });

  final FolderContents contents;
  final VaultViewMode viewMode;

  @override
  Widget build(BuildContext context) {
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
