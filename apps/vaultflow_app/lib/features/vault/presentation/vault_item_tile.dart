import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflict_resolver_sheet.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/vault/presentation/dialogs.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// A folder, document or note shown in a folder listing.
sealed class VaultItem {
  const VaultItem();

  const factory VaultItem.folder(Folder folder) = FolderItem;
  const factory VaultItem.document(Document document) = DocumentItem;
  const factory VaultItem.note(Note note) = NoteItem;

  String get id;
  String get name;
  EntityType get type;
  SyncStatus get syncStatus;
  DateTime get updatedAt;
  IconData get icon;
  String get subtitle;
}

final class FolderItem extends VaultItem {
  const FolderItem(this.folder);
  final Folder folder;

  @override
  String get id => folder.id;
  @override
  String get name => folder.name;
  @override
  EntityType get type => EntityType.folder;
  @override
  SyncStatus get syncStatus => folder.syncStatus;
  @override
  DateTime get updatedAt => folder.updatedAt;
  @override
  IconData get icon => Icons.folder;
  @override
  String get subtitle => 'Folder';
}

final class DocumentItem extends VaultItem {
  const DocumentItem(this.document);
  final Document document;

  @override
  String get id => document.id;
  @override
  String get name => document.name;
  @override
  EntityType get type => EntityType.document;
  @override
  SyncStatus get syncStatus => document.syncStatus;
  @override
  DateTime get updatedAt => document.updatedAt;
  @override
  IconData get icon => switch (document.mimeType.split('/').first) {
    'image' => Icons.image_outlined,
    'video' => Icons.movie_outlined,
    'audio' => Icons.audiotrack_outlined,
    'text' => Icons.description_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
  @override
  String get subtitle =>
      '${formatBytes(document.sizeBytes)}'
      '${document.isAvailableOffline ? ' · offline' : ''}';
}

final class NoteItem extends VaultItem {
  const NoteItem(this.note);
  final Note note;

  @override
  String get id => note.id;
  @override
  String get name => note.title.isEmpty ? 'Untitled note' : note.title;
  @override
  EntityType get type => EntityType.note;
  @override
  SyncStatus get syncStatus => note.syncStatus;
  @override
  DateTime get updatedAt => note.updatedAt;
  @override
  IconData get icon => Icons.sticky_note_2_outlined;
  @override
  String get subtitle => note.preview.isEmpty ? 'Note' : note.preview;
}

/// Shared actions for both tile and card.
class VaultItemActions {
  const VaultItemActions(this.context, this.ref, this.item);

  final BuildContext context;
  final WidgetRef ref;
  final VaultItem item;

  void open() {
    switch (item) {
      case FolderItem(:final folder):
        context.go(AppRoutes.folder(folder.id));
      case NoteItem(:final note):
        context.go(AppRoutes.note(note.id));
      case DocumentItem(:final document):
        _showDocumentSheet(document);
    }
  }

  Future<void> rename() async {
    final name = await showNameDialog(
      context,
      title: 'Rename',
      initialValue: item is NoteItem
          ? (item as NoteItem).note.title
          : item.name,
    );
    if (name == null || !context.mounted) return;
    final result = switch (item) {
      NoteItem(:final note) =>
        await ref
            .read(notesUseCasesProvider)
            .save(id: note.id, title: name, body: note.body),
      _ =>
        await ref
            .read(vaultUseCasesProvider)
            .rename(type: item.type, id: item.id, name: name),
    };
    if (context.mounted) reportResult(context, result);
  }

  Future<void> move() async {
    final excluded = <String>{};
    if (item case FolderItem(:final folder)) {
      excluded.add(folder.id);
    }
    final target = await showMoveDialog(
      context,
      title: 'Move "${item.name}" to…',
      excluded: excluded,
    );
    if (target == null || !context.mounted) return;
    final result = switch (item) {
      NoteItem(:final note) =>
        await ref
            .read(notesUseCasesProvider)
            .move(id: note.id, targetFolderId: target.folderId),
      _ =>
        await ref
            .read(vaultUseCasesProvider)
            .move(
              type: item.type,
              id: item.id,
              targetFolderId: target.folderId,
            ),
    };
    if (context.mounted) reportResult(context, result);
  }

  /// Opens the resolver for this item's open conflict, if any.
  Future<void> resolveConflict() async {
    final conflicts = ref.read(conflictsProvider).value ?? const [];
    final match = conflicts.where((c) => c.entityId == item.id).firstOrNull;
    if (match == null || !context.mounted) return;
    await showConflictResolverSheet(context, match);
  }

  Future<void> delete() async {
    final confirmed = await showDeleteDialog(
      context,
      itemName: item.name,
      isFolder: item is FolderItem,
    );
    if (!confirmed || !context.mounted) return;
    final result = switch (item) {
      NoteItem(:final note) =>
        await ref.read(notesUseCasesProvider).delete(note.id),
      _ =>
        await ref
            .read(vaultUseCasesProvider)
            .delete(type: item.type, id: item.id),
    };
    if (context.mounted) reportResult(context, result);
  }

  void _showDocumentSheet(Document document) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: VfSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: VfSpacing.sm),
              _Detail('Type', document.mimeType),
              _Detail('Size', formatBytes(document.sizeBytes)),
              _Detail('SHA-256', document.sha256, mono: true),
              _Detail('Local copy', switch (document.cacheState) {
                CacheState.complete => 'Available offline',
                CacheState.partial => 'Partially downloaded',
                CacheState.none => 'Not on this device',
              }),
              _Detail(
                'Server',
                document.isUploaded ? 'Uploaded' : 'Waiting for upload',
              ),
              const SizedBox(height: VfSpacing.lg),
              Text(
                'Opening and downloading files arrive with Phase 5.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value, {this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VfSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: mono ? VfTypography.mono : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showActionsSheet(
  BuildContext context,
  VaultItemActions actions,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rename'),
            onTap: () => Navigator.of(context).pop('rename'),
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline),
            title: const Text('Move to…'),
            onTap: () => Navigator.of(context).pop('move'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    ),
  );
  switch (choice) {
    case 'rename':
      await actions.rename();
    case 'move':
      await actions.move();
    case 'delete':
      await actions.delete();
  }
}

PopupMenuButton<String> _menu(VaultItemActions actions) {
  return PopupMenuButton<String>(
    key: Key('item-menu-${actions.item.id}'),
    tooltip: 'More',
    onSelected: (value) => unawaited(switch (value) {
      'resolve' => actions.resolveConflict(),
      'rename' => actions.rename(),
      'move' => actions.move(),
      'delete' => actions.delete(),
      _ => Future<void>.value(),
    }),
    itemBuilder: (context) => [
      if (actions.item.syncStatus == SyncStatus.conflicted)
        const PopupMenuItem(value: 'resolve', child: Text('Resolve conflict…')),
      const PopupMenuItem(value: 'rename', child: Text('Rename')),
      const PopupMenuItem(value: 'move', child: Text('Move to…')),
      const PopupMenuItem(value: 'delete', child: Text('Delete')),
    ],
  );
}

class VaultItemTile extends ConsumerWidget {
  const VaultItemTile({required this.item, super.key});

  final VaultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = VaultItemActions(context, ref, item);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('item-${item.id}'),
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurfaceVariant,
        child: Icon(item.icon),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${item.subtitle} · ${formatRelative(item.updatedAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SyncStatusBadge(status: badgeFor(item.syncStatus), compact: true),
          _menu(actions),
        ],
      ),
      onTap: actions.open,
      onLongPress: () => unawaited(_showActionsSheet(context, actions)),
    );
  }
}

class VaultItemCard extends ConsumerWidget {
  const VaultItemCard({required this.item, super.key});

  final VaultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = VaultItemActions(context, ref, item);
    final theme = Theme.of(context);
    return Card(
      key: Key('item-${item.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actions.open,
        child: Padding(
          padding: const EdgeInsets.all(VfSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: theme.colorScheme.primary),
                  const Spacer(),
                  SyncStatusBadge(
                    status: badgeFor(item.syncStatus),
                    compact: true,
                  ),
                  _menu(actions),
                ],
              ),
              const Spacer(),
              Text(
                item.name,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
