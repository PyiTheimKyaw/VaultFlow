import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Developer view of the sync outbox: every queued op in FIFO order.
class OutboxDebugPage extends ConsumerWidget {
  const OutboxDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(outboxEntriesProvider);
    final theme = Theme.of(context);
    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load outbox',
        message: '$e',
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            key: Key('outbox-empty'),
            icon: Icons.outbox_outlined,
            title: 'Outbox is empty',
            message: 'Every local change has reached the server.',
          );
        }
        final byState = <OutboxState, int>{};
        for (final e in list) {
          byState.update(e.state, (v) => v + 1, ifAbsent: () => 1);
        }
        return ListView(
          key: const Key('outbox-list'),
          padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VfSpacing.lg,
                vertical: VfSpacing.sm,
              ),
              child: Wrap(
                spacing: VfSpacing.sm,
                runSpacing: VfSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    key: const Key('outbox-total'),
                    label: Text('${list.length} queued'),
                  ),
                  ActionChip(
                    key: const Key('outbox-sync-now'),
                    avatar: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync now'),
                    onPressed: () =>
                        ref.read(syncCoordinatorProvider.notifier).syncNow(),
                  ),
                  if (byState.containsKey(OutboxState.failed))
                    ActionChip(
                      key: const Key('outbox-retry-failed'),
                      avatar: const Icon(Icons.replay, size: 18),
                      label: const Text('Retry failed'),
                      onPressed: () => ref
                          .read(syncCoordinatorProvider.notifier)
                          .retryFailed(),
                    ),
                  for (final entry in byState.entries)
                    Chip(label: Text('${entry.value} ${entry.key.name}')),
                ],
              ),
            ),
            for (final e in list)
              ExpansionTile(
                key: Key('outbox-${e.id}'),
                leading: CircleAvatar(
                  radius: 16,
                  child: Text('${e.id}', style: theme.textTheme.labelSmall),
                ),
                title: Text(
                  '${e.op.name.toUpperCase()} ${e.entityType.name}',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  '${e.entityId.substring(0, 8)}… · base v${e.baseVersion} · '
                  '${e.state.name} · ${formatRelative(e.createdAt)}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VfSpacing.lg,
                      0,
                      VfSpacing.lg,
                      VfSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'client_op_id: ${e.clientOpId}',
                          style: VfTypography.mono,
                        ),
                        if (e.dependsOnTransfer != null)
                          Text(
                            'depends_on_transfer: ${e.dependsOnTransfer}',
                            style: VfTypography.mono,
                          ),
                        if (e.lastError != null)
                          Text(
                            'last_error: ${e.lastError}',
                            style: VfTypography.mono.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: VfSpacing.sm),
                        SelectableText(
                          const JsonEncoder.withIndent('  ').convert(e.payload),
                          style: VfTypography.mono,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
