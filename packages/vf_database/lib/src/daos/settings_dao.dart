import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'settings_dao.g.dart';

/// Two key/value stores: `app_settings` (user preferences) and `sync_state`
/// (engine bookkeeping such as the pull cursor).
@DriftAccessor(tables: [AppSettings, SyncState])
class SettingsDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<String?> getSetting(String key) => (select(
    appSettings,
  )..where((s) => s.key.equals(key))).map((row) => row.value).getSingleOrNull();

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((s) => s.key.equals(key)))
          .map((row) => row.value)
          .watchSingleOrNull();

  Future<void> setSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<void> removeSetting(String key) =>
      (delete(appSettings)..where((s) => s.key.equals(key))).go();

  Future<String?> getSyncState(String key) => (select(
    syncState,
  )..where((s) => s.key.equals(key))).map((row) => row.value).getSingleOrNull();

  /// Well-known `sync_state` keys.
  static const String pullCursorKey = 'pull_cursor';
  static const String lastSyncAtKey = 'last_sync_at';
  static const String lastErrorKey = 'last_sync_error';

  Future<int> getPullCursor() async =>
      int.tryParse(await getSyncState(pullCursorKey) ?? '') ?? 0;

  Future<void> setPullCursor(int cursor) =>
      setSyncState(pullCursorKey, '$cursor');

  Future<void> clearSyncState() => delete(syncState).go();

  Future<void> setSyncState(String key, String value) => into(
    syncState,
  ).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
}
