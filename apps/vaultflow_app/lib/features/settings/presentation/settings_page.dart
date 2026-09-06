import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vf_ui/vf_ui.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final queued = ref.watch(outboxCountProvider).value ?? 0;
    return ListView(
      key: const Key('settings'),
      padding: VfSpacing.pagePadding,
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Account'),
          subtitle: Text(session.email ?? 'Not signed in'),
        ),
        const ListTile(
          leading: Icon(Icons.fingerprint),
          title: Text('Vault lock'),
          subtitle: Text('Biometrics and PIN arrive in Phase 3'),
          enabled: false,
        ),
        const Divider(),
        ListTile(
          key: const Key('settings-outbox'),
          leading: const Icon(Icons.outbox_outlined),
          title: const Text('Sync queue'),
          subtitle: Text(
            queued == 0
                ? 'Everything is synced'
                : '$queued change${queued == 1 ? '' : 's'} waiting to sync',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.settingsOutbox),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: ref.read(sessionControllerProvider.notifier).signOut,
        ),
      ],
    );
  }
}
