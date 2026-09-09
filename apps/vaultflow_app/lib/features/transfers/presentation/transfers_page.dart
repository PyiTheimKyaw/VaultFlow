import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_transfer/vf_transfer.dart';
import 'package:vf_ui/vf_ui.dart';

/// Upload/download queue with progress, speed, ETA and controls.
class TransfersPage extends ConsumerWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(transferSessionsProvider);
    final progress = ref.watch(transferProgressProvider).value ?? const {};
    final documents = ref.watch(transferDocumentsProvider).value ?? const {};
    final saved = ref.watch(dedupeSavedBytesProvider).value ?? 0;
    final engine = ref.watch(transferEngineProvider);

    return sessions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load transfers',
        message: '$e',
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            key: Key('transfers'),
            icon: Icons.swap_vert_outlined,
            title: 'No transfers',
            message:
                'Imported files upload here in resumable chunks; files you '
                'open or keep offline download here.',
          );
        }
        final finished = list.where((s) => s.transferState.isTerminal).length;
        return ListView(
          key: const Key('transfers-list'),
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
                  Chip(label: Text('${list.length - finished} active')),
                  if (saved > 0)
                    Chip(
                      key: const Key('transfers-dedupe'),
                      avatar: const Icon(Icons.bolt, size: 18),
                      label: Text('${formatBytes(saved)} saved by dedupe'),
                    ),
                  if (finished > 0)
                    ActionChip(
                      key: const Key('transfers-clear'),
                      label: const Text('Clear finished'),
                      onPressed: () => unawaited(engine.clearFinished()),
                    ),
                ],
              ),
            ),
            for (final session in list)
              _TransferTile(
                session: session,
                document: documents[session.documentId],
                progress: progress[session.id],
                engine: engine,
              ),
          ],
        );
      },
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.session,
    required this.document,
    required this.progress,
    required this.engine,
  });

  final TransferSessionRow session;
  final DocumentRow? document;
  final TransferProgress? progress;
  final TransferEngine engine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = session.transferState;
    final isUpload = session.transferKind == TransferKind.upload;
    final done = progress?.bytesDone ?? session.bytesDone;
    final total = session.totalBytes;
    final fraction = total == 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
    final speed = progress?.bytesPerSecond ?? 0;
    final eta = progress?.eta;

    final status = switch (state) {
      TransferState.running =>
        speed > 0
            ? '${formatBytes(speed.round())}/s'
                  '${eta == null ? '' : ' · ${_eta(eta)} left'}'
            : 'Starting…',
      TransferState.queued =>
        session.attemptCount > 0
            ? 'Retrying (attempt ${session.attemptCount + 1})'
            : 'Queued',
      TransferState.paused => 'Paused',
      TransferState.failed => session.lastError ?? 'Failed',
      TransferState.completed => 'Done',
      TransferState.cancelled => 'Cancelled',
    };

    return ListTile(
      key: Key('transfer-${session.id}'),
      leading: Icon(
        isUpload ? Icons.cloud_upload_outlined : Icons.cloud_download_outlined,
        color: state == TransferState.failed ? theme.colorScheme.error : null,
      ),
      title: Text(
        document?.name ?? session.localPath.split('/').last,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VfSpacing.xs),
          if (!state.isTerminal)
            LinearProgressIndicator(
              value: state == TransferState.running && speed == 0 && done == 0
                  ? null
                  : fraction,
            ),
          const SizedBox(height: VfSpacing.xs),
          Text(
            '${formatBytes(done)} / ${formatBytes(total)} · $status',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: state == TransferState.failed
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == TransferState.running || state == TransferState.queued)
            IconButton(
              key: Key('transfer-pause-${session.id}'),
              tooltip: 'Pause',
              icon: const Icon(Icons.pause),
              onPressed: () => unawaited(engine.pause(session.id)),
            ),
          if (state == TransferState.paused)
            IconButton(
              key: Key('transfer-resume-${session.id}'),
              tooltip: 'Resume',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => unawaited(engine.resume(session.id)),
            ),
          if (state == TransferState.failed)
            IconButton(
              key: Key('transfer-retry-${session.id}'),
              tooltip: 'Retry',
              icon: const Icon(Icons.replay),
              onPressed: () => unawaited(engine.retry(session.id)),
            ),
          if (!state.isTerminal)
            IconButton(
              key: Key('transfer-cancel-${session.id}'),
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () => unawaited(engine.cancel(session.id)),
            ),
        ],
      ),
    );
  }

  static String _eta(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}
