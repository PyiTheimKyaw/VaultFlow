import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/app.dart';
import 'package:vaultflow_app/app/bootstrap.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/auth/data/secure_token_store.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vaultflow_app/features/vault/application/share_intent.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_security/vf_security.dart';

const _log = Logger('main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();

  final secureStore = KeychainSecureStore();
  final VaultFlowDatabase db;
  try {
    final keys = DbKeyProvider(secureStore);
    db = await openVaultFlowDatabase(keyLoader: keys.getOrCreate);
  } on Object catch (error, stackTrace) {
    _log.error('database failed to open', error: error, stackTrace: stackTrace);
    runApp(StartupErrorApp(error: error));
    return;
  }

  // Restore the session before the first frame so the router starts on the
  // right page instead of flashing the login screen.
  final tokens = await SecureTokenStore(secureStore).read();
  final initialSession = tokens == null
      ? const SignedOut()
      : SignedIn(userId: tokens.userId, deviceId: tokens.deviceId, email: null);

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      secureStoreProvider.overrideWithValue(secureStore),
      initialSessionProvider.overrideWithValue(initialSession),
    ],
  );
  await container.read(appLockControllerProvider).initialize();
  await container.read(transferEngineProvider).recover();
  await container.read(shareIntentImporterProvider)?.start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VaultFlowApp(),
    ),
  );
}

/// Shown when the local database cannot be opened. There is nothing useful
/// the app can do without it, so explain instead of crashing.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'VaultFlow could not open its local vault.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
