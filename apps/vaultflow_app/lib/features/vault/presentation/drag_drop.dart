import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/vault/application/vault_selection.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// What an in-app drag carries: one item, or the whole selection when the
/// dragged item is part of it.
@immutable
class VaultDragPayload {
  const VaultDragPayload(this.items);

  final List<VaultRef> items;

  /// Folder ids that must not accept this payload (a folder cannot be
  /// dropped on itself; the use case rejects descendants).
  Set<String> get folderIds => {
    for (final i in items)
      if (i.type == EntityType.folder) i.id,
  };
}

/// Whether drags start with the mouse (desktop, web) or a long press.
bool get usesMouseDrag =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };

/// Makes [child] draggable with a compact feedback chip.
///
/// Desktop and web drag with the mouse. Touch platforms use a long press
/// for both gestures: long-press-and-move drags, long-press-and-release
/// calls [onLongPressSelect] (selection), so the two never fight in the
/// gesture arena.
Widget vaultDraggable({
  required VaultDragPayload payload,
  required Widget child,
  required BuildContext context,
  VoidCallback? onLongPressSelect,
}) {
  final label = payload.items.length == 1
      ? payload.items.single.name
      : '${payload.items.length} items';
  final feedback = Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(VfRadius.md),
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VfSpacing.md,
        vertical: VfSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge,
        maxLines: 1,
      ),
    ),
  );
  final ghost = Opacity(opacity: 0.4, child: child);
  return usesMouseDrag
      ? Draggable<VaultDragPayload>(
          data: payload,
          feedback: feedback,
          childWhenDragging: ghost,
          child: child,
        )
      : _TouchDraggable(
          payload: payload,
          feedback: feedback,
          ghost: ghost,
          onSelect: onLongPressSelect,
          child: child,
        );
}

class _TouchDraggable extends StatefulWidget {
  const _TouchDraggable({
    required this.payload,
    required this.feedback,
    required this.ghost,
    required this.child,
    this.onSelect,
  });

  final VaultDragPayload payload;
  final Widget feedback;
  final Widget ghost;
  final Widget child;
  final VoidCallback? onSelect;

  @override
  State<_TouchDraggable> createState() => _TouchDraggableState();
}

class _TouchDraggableState extends State<_TouchDraggable> {
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<VaultDragPayload>(
      data: widget.payload,
      feedback: widget.feedback,
      childWhenDragging: widget.ghost,
      onDragStarted: () => _moved = false,
      onDragUpdate: (d) {
        if (d.delta.distance > 0) _moved = true;
      },
      onDraggableCanceled: (_, _) {
        if (!_moved) widget.onSelect?.call();
      },
      child: widget.child,
    );
  }
}

/// Accepts dragged items and moves them into [folderId] (`null` = root).
/// Highlights while a valid payload hovers.
class FolderDropTarget extends ConsumerWidget {
  const FolderDropTarget({
    required this.folderId,
    required this.builder,
    super.key,
  });

  final String? folderId;

  /// Builds the child; the flag is true while an acceptable drag is over.
  final Widget Function(BuildContext context, bool hovering) builder;

  bool _accepts(VaultDragPayload? payload) =>
      payload != null &&
      payload.items.isNotEmpty &&
      (folderId == null || !payload.folderIds.contains(folderId));

  Future<void> _drop(
    BuildContext context,
    WidgetRef ref,
    VaultDragPayload payload,
  ) async {
    final result = await ref
        .read(vaultBatchActionsProvider)
        .move(payload.items, folderId);
    ref.read(vaultSelectionProvider.notifier).clear();
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        reportResult(
          context,
          okVoid,
          successMessage: value == 1 ? 'Moved 1 item' : 'Moved $value items',
        );
      case Err():
        reportResult(context, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<VaultDragPayload>(
      key: Key('drop-${folderId ?? 'root'}'),
      onWillAcceptWithDetails: (d) => _accepts(d.data),
      onAcceptWithDetails: (d) => unawaited(_drop(context, ref, d.data)),
      builder: (context, candidates, _) =>
          builder(context, candidates.isNotEmpty),
    );
  }
}
