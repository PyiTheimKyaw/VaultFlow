import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vf_sync/vf_sync.dart';
import 'package:vf_ui/vf_ui.dart';

/// Everything the badge needs, folded into one value.
class SyncSummary {
  const SyncSummary({
    required this.badge,
    required this.engine,
    required this.pending,
    required this.failed,
    required this.conflicts,
  });

  final SyncBadgeStatus badge;
  final SyncEngineState engine;
  final int pending;
  final int failed;
  final int conflicts;

  String get headline => switch (badge) {
    SyncBadgeStatus.syncing => 'Syncing…',
    SyncBadgeStatus.offline => 'Offline — changes are saved on this device',
    SyncBadgeStatus.error => 'Sync failed: ${engine.lastError?.message}',
    SyncBadgeStatus.conflicted =>
      '$conflicts conflict${conflicts == 1 ? '' : 's'} need attention',
    SyncBadgeStatus.pending =>
      '$pending change${pending == 1 ? '' : 's'} waiting to sync',
    SyncBadgeStatus.synced => 'Everything is synced',
  };
}

final Provider<SyncSummary> syncSummaryProvider =
    Provider.autoDispose<SyncSummary>((ref) {
      final engine =
          ref.watch(syncStateProvider).value ?? const SyncEngineState();
      final pending = ref.watch(outboxCountProvider).value ?? 0;
      final failed = ref.watch(failedOutboxCountProvider).value ?? 0;
      final conflicts = ref.watch(conflictsProvider).value?.length ?? 0;
      final badge = engine.isSyncing
          ? SyncBadgeStatus.syncing
          : conflicts > 0
          ? SyncBadgeStatus.conflicted
          : failed > 0 || (engine.lastError != null && !engine.offline)
          ? SyncBadgeStatus.error
          : engine.offline
          ? SyncBadgeStatus.offline
          : pending > 0
          ? SyncBadgeStatus.pending
          : SyncBadgeStatus.synced;
      return SyncSummary(
        badge: badge,
        engine: engine,
        pending: pending,
        failed: failed,
        conflicts: conflicts,
      );
    });

/// App-bar badge; tapping opens the status sheet.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(syncSummaryProvider);
    return SyncStatusBadge(
      key: const Key('shell-sync-badge'),
      status: summary.badge,
      onTap: () => showSyncStatusSheet(context),
    );
  }
}

Future<void> showSyncStatusSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SyncStatusSheet(),
    );

class SyncStatusSheet extends ConsumerWidget {
  const SyncStatusSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(syncSummaryProvider);
    final theme = Theme.of(context);
    final lastSync = summary.engine.lastSyncAt;
    return SafeArea(
      child: Padding(
        padding: VfSpacing.pagePadding,
        child: Column(
          key: const Key('sync-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SyncStatusBadge(status: summary.badge),
                const SizedBox(width: VfSpacing.md),
                Expanded(
                  child: Text(
                    summary.headline,
                    key: const Key('sync-headline'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VfSpacing.sm),
            Text(
              lastSync == null
                  ? 'Not synced yet on this device'
                  : 'Last synced ${formatRelative(lastSync)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: VfSpacing.lg),
            if (summary.conflicts > 0)
              ListTile(
                key: const Key('sync-sheet-conflicts'),
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                  'Resolve ${summary.conflicts} conflict'
                  '${summary.conflicts == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.settingsConflicts);
                },
              ),
            if (summary.failed > 0)
              ListTile(
                key: const Key('sync-sheet-retry'),
                leading: const Icon(Icons.replay),
                title: Text(
                  'Retry ${summary.failed} failed change'
                  '${summary.failed == 1 ? '' : 's'}',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    ref.read(syncCoordinatorProvider.notifier).retryFailed(),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.outbox_outlined),
              title: const Text('Sync queue'),
              subtitle: Text('${summary.pending} waiting'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.settingsOutbox);
              },
            ),
            const SizedBox(height: VfSpacing.md),
            FilledButton.icon(
              key: const Key('sync-now'),
              onPressed: summary.engine.isSyncing
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      unawaited(
                        ref.read(syncCoordinatorProvider.notifier).syncNow(),
                      );
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
          ],
        ),
      ),
    );
  }
}
