import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflicts_page.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

Future<void> showConflictResolverSheet(
  BuildContext context,
  Conflict conflict,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => ConflictResolverSheet(conflict: conflict),
);

/// Side-by-side view of both versions with the three resolutions.
class ConflictResolverSheet extends ConsumerStatefulWidget {
  const ConflictResolverSheet({required this.conflict, super.key});

  final Conflict conflict;

  @override
  ConsumerState<ConflictResolverSheet> createState() =>
      _ConflictResolverSheetState();
}

class _ConflictResolverSheetState extends ConsumerState<ConflictResolverSheet> {
  bool _busy = false;

  Future<void> _choose(ConflictResolution choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(syncCoordinatorProvider.notifier)
        .resolve(widget.conflict.id, choice);
    if (!mounted) return;
    setState(() => _busy = false);
    if (reportResult(context, result, successMessage: 'Conflict resolved')) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conflict;
    final theme = Theme.of(context);
    final remoteDeleted = c.remoteSnapshot['deleted_at'] != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: VfSpacing.pagePadding,
        child: Column(
          key: const Key('conflict-resolver'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(iconFor(c.entityType), color: theme.colorScheme.error),
                const SizedBox(width: VfSpacing.sm),
                Expanded(
                  child: Text(
                    displayName(c.localSnapshot, c.entityType),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VfSpacing.xs),
            Text(
              'This ${c.entityType.name} was changed on another device '
              'while you edited it here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VfSpacing.lg),
            _Version(
              label: 'On this device',
              snapshot: c.localSnapshot,
              type: c.entityType,
            ),
            const SizedBox(height: VfSpacing.md),
            _Version(
              label: remoteDeleted
                  ? 'On the server (deleted)'
                  : 'On the server (v${c.remoteVersion})',
              snapshot: c.remoteSnapshot,
              type: c.entityType,
            ),
            const SizedBox(height: VfSpacing.xl),
            FilledButton(
              key: const Key('resolve-keep-local'),
              onPressed: _busy
                  ? null
                  : () => _choose(ConflictResolution.keepLocal),
              child: const Text('Keep mine'),
            ),
            const SizedBox(height: VfSpacing.sm),
            OutlinedButton(
              key: const Key('resolve-keep-remote'),
              onPressed: _busy
                  ? null
                  : () => _choose(ConflictResolution.keepRemote),
              child: const Text('Keep theirs'),
            ),
            const SizedBox(height: VfSpacing.sm),
            TextButton(
              key: const Key('resolve-keep-both'),
              onPressed: _busy
                  ? null
                  : () => _choose(ConflictResolution.keepBoth),
              child: const Text('Keep both (save mine as a copy)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Version extends StatelessWidget {
  const _Version({
    required this.label,
    required this.snapshot,
    required this.type,
  });

  final String label;
  final Map<String, Object?> snapshot;
  final EntityType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = snapshot['body'];
    final updated = snapshot['updated_at'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VfSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: VfSpacing.xs),
            Text(
              snapshot.isEmpty ? '(missing)' : displayName(snapshot, type),
              style: theme.textTheme.titleSmall,
            ),
            if (body is String && body.isNotEmpty) ...[
              const SizedBox(height: VfSpacing.xs),
              Text(
                body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (updated is String) ...[
              const SizedBox(height: VfSpacing.xs),
              Text(
                'Edited $updated',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
