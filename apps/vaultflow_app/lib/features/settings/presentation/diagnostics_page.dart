import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/bootstrap.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/environment.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_ui/vf_ui.dart';

/// Environment, sync and transfer state, and the recent log tail, with a
/// one-tap copy for bug reports. Nothing here leaves the device unless the
/// user pastes it somewhere.
class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  String _report(WidgetRef ref, List<LogRecord> logs) {
    final session = ref.read(sessionControllerProvider);
    final engine = ref.read(syncCoordinatorProvider);
    final sessions = ref.read(transferSessionsProvider).value ?? const [];
    final lines = <String>[
      'VaultFlow ${AppEnvironment.appVersion} (${AppEnvironment.name})',
      'api: ${AppEnvironment.apiBaseUrl}',
      'device: ${session is SignedIn ? session.deviceId : 'signed out'}',
      'sync: ${engine?.state.value.phase.name ?? 'off'} '
              'last=${engine?.state.value.lastSyncAt?.toIso8601String() ?? '-'} '
              'error=${engine?.state.value.lastError?.message ?? '-'}'
          .trim(),
      'transfers: ${sessions.length} '
              '(${sessions.where((s) => s.state == 'failed').length} failed)'
          .trim(),
      '',
      '--- log tail (${logs.length}) ---',
      for (final r in logs) '$r',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final engine = ref.watch(syncCoordinatorProvider);
    final outbox = ref.watch(outboxCountProvider).value ?? 0;
    final sessions = ref.watch(transferSessionsProvider).value ?? const [];
    final saved = ref.watch(dedupeSavedBytesProvider).value ?? 0;
    final logs = appLogBuffer.records.reversed.take(200).toList();
    final theme = Theme.of(context);

    Widget row(String label, String value, {Key? key}) => ListTile(
      key: key,
      dense: true,
      title: Text(label),
      subtitle: Text(value, style: VfTypography.mono),
    );

    return ListView(
      key: const Key('diagnostics'),
      padding: VfSpacing.pagePadding,
      children: [
        row(
          'Build',
          '${AppEnvironment.appVersion} · ${AppEnvironment.name}'
              '${AppEnvironment.crashReportingEnabled ? ' · crash reports on' : ''}',
          key: const Key('diag-build'),
        ),
        row('API', AppEnvironment.apiBaseUrl),
        row('Device', session is SignedIn ? session.deviceId : 'signed out'),
        const Divider(),
        ListenableBuilder(
          listenable: engine?.state ?? ValueNotifier(null),
          builder: (context, _) {
            final state = engine?.state.value;
            return row(
              'Sync',
              state == null
                  ? 'off'
                  : '${state.phase.name} · last '
                        '${state.lastSyncAt == null ? 'never' : formatRelative(state.lastSyncAt!)}'
                        '${state.lastError == null ? '' : ' · ${state.lastError!.message}'}'
                        ' · $outbox queued',
              key: const Key('diag-sync'),
            );
          },
        ),
        row(
          'Transfers',
          '${sessions.length} sessions · '
              '${sessions.where((s) => s.state == 'failed').length} failed · '
              '${formatBytes(saved)} saved by dedupe',
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
          child: Row(
            children: [
              Text('Recent log', style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                key: const Key('diag-copy'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _report(ref, logs.reversed.toList())),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Diagnostics copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy report'),
              ),
            ],
          ),
        ),
        if (logs.isEmpty)
          const Text('No log entries yet.')
        else
          for (final r in logs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VfSpacing.xxs),
              child: Text(
                '${r.time.toIso8601String().substring(11, 19)} '
                '${r.level.name.toUpperCase()} [${r.tag}] ${r.message}'
                '${r.fields.isEmpty ? '' : ' ${r.fields}'}',
                style: VfTypography.mono.copyWith(
                  fontSize: 11,
                  color: r.level >= LogLevel.warning
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ),
      ],
    );
  }
}
