import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_security/vf_security.dart';

part 'wipe_service.g.dart';

const _log = Logger('wipe');

/// "Sign out" means nothing of the vault remains on the device: every
/// table, cached file, token and PIN. The database key is kept so the
/// (now empty) database stays openable.
final class WipeService {
  const WipeService({
    required this.db,
    required this.tokens,
    required this.pin,
    required this.cacheDirectory,
    required this.lockSettings,
  });

  final VaultFlowDatabase db;
  final TokenStore tokens;
  final PinVault pin;
  final CacheDirectory cacheDirectory;
  final LockSettingsStore lockSettings;

  Future<void> wipeAll() async {
    await tokens.clear();
    await pin.clear();
    await lockSettings.save(const LockSettings());
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.delete(table).go();
      }
    });
    if (!kIsWeb) {
      try {
        final dir = Directory(await cacheDirectory.cacheRoot());
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on Object catch (error) {
        _log.warning('could not delete cache directory', error: error);
      }
    }
    _log.info('local data wiped');
  }
}

@Riverpod(keepAlive: true)
WipeService wipeService(Ref ref) => WipeService(
  db: ref.watch(databaseProvider),
  tokens: ref.watch(tokenStoreProvider),
  pin: ref.watch(pinVaultProvider),
  cacheDirectory: ref.watch(cacheDirectoryProvider),
  lockSettings: ref.watch(lockSettingsStoreProvider),
);
