import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vaultflow_app/features/auth/application/device_info.dart';
import 'package:vaultflow_app/features/auth/data/secure_token_store.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_security/vf_security.dart';
import 'package:vf_sync/vf_sync.dart';
import 'package:workmanager/workmanager.dart';

const _log = Logger('background_sync');

/// Identifier shared by Dart, `Info.plist` and `AppDelegate.swift`.
const String backgroundSyncTask = 'dev.vaultflow.sync';

/// API origin, duplicated here because the background isolate does not
/// share `di.dart`'s constant at runtime (it is a compile-time define).
const String _apiBaseUrl = String.fromEnvironment(
  'VAULTFLOW_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

bool get supportsBackgroundSync =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Registers the periodic task (Android WorkManager / iOS BGTaskScheduler).
/// Best effort: the OS decides when it actually runs.
Future<void> registerBackgroundSync() async {
  if (!supportsBackgroundSync) return;
  try {
    await Workmanager().initialize(backgroundSyncDispatcher);
    await Workmanager().registerPeriodicTask(
      'vaultflow-periodic-sync',
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
    _log.info('background sync registered');
  } on Object catch (error) {
    _log.warning('could not register background sync', error: error);
  }
}

Future<void> cancelBackgroundSync() async {
  if (!supportsBackgroundSync) return;
  try {
    await Workmanager().cancelByUniqueName('vaultflow-periodic-sync');
  } on Object catch (error) {
    _log.warning('could not cancel background sync', error: error);
  }
}

/// Entry point of the background isolate: opens the vault and runs one
/// sync round. Nothing from the foreground isolate is available here.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundSyncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    final secureStore = KeychainSecureStore();
    final tokenStore = SecureTokenStore(secureStore);
    final tokens = await tokenStore.read();
    if (tokens == null) return true; // signed out: nothing to do
    VaultFlowDatabase? db;
    try {
      db = await openVaultFlowDatabase(
        keyLoader: DbKeyProvider(secureStore).getOrCreate,
      );
      final api = ApiClient(
        DioFactory.create(
          baseUrl: _apiBaseUrl,
          tokens: tokenStore,
          onAuthLost: () {},
        ),
      );
      final engine = SyncEngine(
        db: db,
        api: api,
        deviceId: tokens.deviceId,
        deviceLabel: DeviceInfo.name,
      );
      await engine.recover();
      final report = await engine.syncNow();
      engine.dispose();
      _log.info(
        'background sync done',
        fields: {'applied': report.push.applied, 'pulled': report.pull.applied},
      );
      return report.isOk;
    } on Object catch (error, stackTrace) {
      _log.error(
        'background sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      await db?.close();
    }
  });
}
