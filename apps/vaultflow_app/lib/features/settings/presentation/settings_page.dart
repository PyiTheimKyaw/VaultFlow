import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vf_ui/vf_ui.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your vault stays on the server. Everything stored on this '
          'device, including files kept offline, will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('sign-out-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(sessionControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final queued = ref.watch(outboxCountProvider).value ?? 0;
    final lock = ref.watch(appLockControllerProvider);
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) => ListView(
        key: const Key('settings'),
        padding: VfSpacing.pagePadding,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            subtitle: Text(session.email ?? 'Signed in'),
          ),
          ListTile(
            key: const Key('settings-lock'),
            leading: const Icon(Icons.fingerprint),
            title: const Text('Vault lock'),
            subtitle: Text(
              lock.hasPin
                  ? (lock.settings.biometricsEnabled
                        ? 'PIN and biometrics'
                        : 'PIN')
                  : 'Off — set a PIN to lock the vault',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.settingsLock),
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
            key: const Key('settings-sign-out'),
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            subtitle: const Text('Removes all vault data from this device'),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
