import 'package:vf_database/vf_database.dart';
import 'package:vf_security/vf_security.dart';

/// [LockSettingsStore] on the `app_settings` table.
final class DbLockSettingsStore implements LockSettingsStore {
  const DbLockSettingsStore(this._settings);

  static const String timeoutKey = 'lock_timeout_s';
  static const String biometricsKey = 'biometrics_enabled';

  final SettingsDao _settings;

  @override
  Future<LockSettings> load() async {
    final timeout = int.tryParse(await _settings.getSetting(timeoutKey) ?? '');
    final biometrics = await _settings.getSetting(biometricsKey);
    return LockSettings(
      timeout: Duration(seconds: timeout ?? 0),
      biometricsEnabled: biometrics == 'true',
    );
  }

  @override
  Future<void> save(LockSettings settings) async {
    await _settings.setSetting(timeoutKey, '${settings.timeout.inSeconds}');
    await _settings.setSetting(biometricsKey, '${settings.biometricsEnabled}');
  }
}
