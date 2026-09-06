import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/src/database.dart';

const _log = Logger('vf_database');

Future<VaultFlowDatabase> openDatabase({
  required String name,
  required Future<String> Function() keyLoader,
}) async {
  final key = await keyLoader();
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'vaultflow', '$name.db'));
  await file.parent.create(recursive: true);
  _log.debug('opening database', fields: {'path': file.path});

  final executor = NativeDatabase.createInBackground(
    file,
    setup: (raw) => applyKey(raw, key),
  );
  return VaultFlowDatabase(executor);
}

/// Unlocks [raw] with [key] and enables WAL. Also used by tests against an
/// in-memory database to prove the cipher is active.
void applyKey(Database raw, String key) {
  final escaped = key.replaceAll("'", "''");
  raw.execute("PRAGMA key = '$escaped'");
  final cipher = raw.select('PRAGMA cipher');
  if (cipher.isEmpty) {
    throw StateError(
      'Bundled SQLite has no cipher support; refusing to open an '
      'unencrypted vault. Check the sqlite3 hook user_defines.',
    );
  }
  // Forces a read so a wrong key fails here instead of on first query.
  raw
    ..select('SELECT count(*) FROM sqlite_master')
    ..execute('PRAGMA journal_mode = WAL');
}
