import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflict_resolver_sheet.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vaultflow_app/features/vault/application/vault_selection.dart';
import 'package:vaultflow_app/features/vault/presentation/dialogs.dart';
import 'package:vaultflow_app/features/vault/presentation/drag_drop.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_transfer/vf_transfer.dart';
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

  VaultRef get asRef => (type: type, id: id, name: name);
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

  /// Desktop right-click menu at [globalPosition].
  Future<void> showContextMenu(Offset globalPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: menuItems(),
    );
    if (choice != null && context.mounted) await run(choice);
  }

  List<PopupMenuEntry<String>> menuItems() => [
    if (item.syncStatus == SyncStatus.conflicted)
      const PopupMenuItem(value: 'resolve', child: Text('Resolve conflict…')),
    const PopupMenuItem(value: 'rename', child: Text('Rename')),
    const PopupMenuItem(value: 'move', child: Text('Move to…')),
    const PopupMenuItem(value: 'delete', child: Text('Delete')),
  ];

  Future<void> run(String action) => switch (action) {
    'resolve' => resolveConflict(),
    'rename' => rename(),
    'move' => move(),
    'delete' => delete(),
    _ => Future<void>.value(),
  };

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
        builder: (_) => DocumentSheet(documentId: document.id),
      ),
    );
  }
}

/// Details plus the transfer actions: open, download, keep offline.
class DocumentSheet extends ConsumerWidget {
  const DocumentSheet({required this.documentId, super.key});

  final String documentId;

  /// Web: the browser saves the file through a short-lived signed link.
  Future<void> _downloadViaLink(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final api = ref.read(apiClientProvider);
    final result = await api.createDownloadUrl(doc.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        final opened = await ref.read(urlOpenerProvider)(
          api.absolute(value.url),
        );
        if (!opened && context.mounted) {
          reportResult(
            context,
            const Err<void>(UnexpectedFailure('Could not open the download')),
          );
        }
      case Err():
        reportResult(context, result);
    }
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Document doc) async {
    if (doc.isAvailableOffline && doc.localPath != null) {
      final opened = await ref.read(urlOpenerProvider)(
        Uri.file(doc.localPath!),
      );
      if (!opened && context.mounted) {
        reportResult(
          context,
          const Err<void>(UnexpectedFailure('No app can open this file')),
        );
      }
      return;
    }
    await ref.read(transferEngineProvider).enqueueDownload(doc);
    if (context.mounted) {
      reportResult(context, okVoid, successMessage: 'Downloading ${doc.name}…');
    }
  }

  Future<void> _setOffline(WidgetRef ref, Document doc, bool keep) async {
    if (keep) {
      await ref.read(transferEngineProvider).enqueueDownload(doc);
    } else {
      final path = doc.localPath;
      if (path != null && !ref.read(isWebProvider)) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
      await ref
          .read(vaultRepositoryProvider)
          .updateDocumentCache(doc.id, cacheState: CacheState.none);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentProvider(documentId));
    final sessions = ref.watch(transferSessionsProvider).value ?? const [];
    final progress = ref.watch(transferProgressProvider).value ?? const {};
    final theme = Theme.of(context);
    final document = docAsync.value;
    if (document == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Document not found')),
      );
    }
    final active = sessions
        .where((s) => s.documentId == documentId && !s.transferState.isTerminal)
        .firstOrNull;
    final activeProgress = active == null ? null : progress[active.id];
    final downloading =
        active != null && active.transferKind == TransferKind.download;

    return SafeArea(
      child: SingleChildScrollView(
        padding: VfSpacing.pagePadding,
        child: Column(
          key: const Key('document-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.name, style: theme.textTheme.titleLarge),
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
              document.isUploaded
                  ? 'Uploaded'
                  : active?.transferKind == TransferKind.upload
                  ? 'Uploading…'
                  : 'Waiting for upload',
            ),
            if (active != null) ...[
              const SizedBox(height: VfSpacing.md),
              LinearProgressIndicator(
                key: const Key('document-progress'),
                value: active.totalBytes == 0
                    ? 1
                    : (activeProgress?.bytesDone ?? active.bytesDone) /
                          active.totalBytes,
              ),
              const SizedBox(height: VfSpacing.xs),
              Text(
                '${downloading ? 'Downloading' : 'Uploading'} · '
                '${formatBytes(activeProgress?.bytesDone ?? active.bytesDone)} '
                'of ${formatBytes(active.totalBytes)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: VfSpacing.lg),
            if (!ref.watch(isWebProvider)) ...[
              SwitchListTile(
                key: const Key('document-offline'),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.offline_pin_outlined),
                title: const Text('Keep available offline'),
                subtitle: Text(
                  document.isUploaded
                      ? 'Stores a verified copy in the encrypted cache'
                      : 'The local copy stays until the upload finishes',
                ),
                value: document.isAvailableOffline || downloading,
                // Until the server has the bytes, the local copy is the only
                // one: never offer to delete it.
                onChanged: document.isUploaded
                    ? (v) => unawaited(_setOffline(ref, document, v))
                    : null,
              ),
              const SizedBox(height: VfSpacing.sm),
              FilledButton.icon(
                key: const Key('document-open'),
                onPressed: document.isUploaded || document.isAvailableOffline
                    ? () => unawaited(_open(context, ref, document))
                    : null,
                icon: Icon(
                  document.isAvailableOffline
                      ? Icons.open_in_new
                      : Icons.cloud_download_outlined,
                ),
                label: Text(document.isAvailableOffline ? 'Open' : 'Download'),
              ),
            ] else
              FilledButton.icon(
                key: const Key('document-download-link'),
                onPressed: document.isUploaded
                    ? () => unawaited(_downloadViaLink(context, ref, document))
                    : null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download'),
              ),
          ],
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

PopupMenuButton<String> _menu(VaultItemActions actions) {
  return PopupMenuButton<String>(
    key: Key('item-menu-${actions.item.id}'),
    tooltip: 'More',
    onSelected: (value) => unawaited(actions.run(value)),
    itemBuilder: (context) => actions.menuItems(),
  );
}

/// Selection-aware tap handling shared by tile and card:
/// * selection active → tap toggles;
/// * ⌘/Ctrl-click → toggles (desktop);
/// * otherwise opens.
void _handleTap(WidgetRef ref, VaultItem item, VaultItemActions actions) {
  final selection = ref.read(vaultSelectionProvider.notifier);
  final modifier =
      HardwareKeyboard.instance.isMetaPressed ||
      HardwareKeyboard.instance.isControlPressed;
  if (ref.read(vaultSelectionProvider).isNotEmpty || modifier) {
    selection.toggle(item.asRef);
  } else {
    actions.open();
  }
}

/// Wraps [child] with drag source, folder drop target and right-click menu.
Widget _interactive({
  required BuildContext context,
  required WidgetRef ref,
  required VaultItem item,
  required VaultItemActions actions,
  required Widget Function(bool hovering) child,
}) {
  final selected = ref.watch(vaultSelectionProvider);
  final payload = VaultDragPayload(
    selected.containsKey(item.id)
        ? [item.asRef, ...selected.values.where((r) => r.id != item.id)]
        : [item.asRef],
  );
  var inner = item is FolderItem
      ? FolderDropTarget(
          folderId: item.id,
          builder: (context, hovering) => child(hovering),
        )
      : child(false);
  inner = GestureDetector(
    onSecondaryTapUp: (d) =>
        unawaited(actions.showContextMenu(d.globalPosition)),
    child: inner,
  );
  return vaultDraggable(
    payload: payload,
    context: context,
    onLongPressSelect: () =>
        ref.read(vaultSelectionProvider.notifier).toggle(item.asRef),
    child: inner,
  );
}

class VaultItemTile extends ConsumerWidget {
  const VaultItemTile({required this.item, super.key});

  final VaultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = VaultItemActions(context, ref, item);
    final scheme = Theme.of(context).colorScheme;
    final selection = ref.watch(vaultSelectionProvider);
    final selecting = selection.isNotEmpty;
    final isSelected = selection.containsKey(item.id);
    return _interactive(
      context: context,
      ref: ref,
      item: item,
      actions: actions,
      child: (hovering) => ListTile(
        key: Key('item-${item.id}'),
        selected: isSelected,
        selectedTileColor: scheme.secondaryContainer,
        tileColor: hovering ? scheme.tertiaryContainer : null,
        leading: selecting
            ? Checkbox(
                key: Key('item-check-${item.id}'),
                value: isSelected,
                onChanged: (_) => ref
                    .read(vaultSelectionProvider.notifier)
                    .toggle(item.asRef),
              )
            : CircleAvatar(
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
        onTap: () => _handleTap(ref, item, actions),
      ),
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
    final selection = ref.watch(vaultSelectionProvider);
    final isSelected = selection.containsKey(item.id);
    return _interactive(
      context: context,
      ref: ref,
      item: item,
      actions: actions,
      child: (hovering) => Card(
        key: Key('item-${item.id}'),
        clipBehavior: Clip.antiAlias,
        color: isSelected
            ? theme.colorScheme.secondaryContainer
            : hovering
            ? theme.colorScheme.tertiaryContainer
            : null,
        child: InkWell(
          onTap: () => _handleTap(ref, item, actions),
          child: Padding(
            padding: const EdgeInsets.all(VfSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selection.isNotEmpty)
                      Checkbox(
                        key: Key('item-check-${item.id}'),
                        value: isSelected,
                        onChanged: (_) => ref
                            .read(vaultSelectionProvider.notifier)
                            .toggle(item.asRef),
                      )
                    else
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
      ),
    );
  }
}
