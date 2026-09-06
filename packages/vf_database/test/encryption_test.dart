import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:vf_database/src/connection/open_database_native.dart';
import 'package:vf_database/vf_database.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vf_db_');
    file = File(p.join(dir.path, 'vault.db'));
  });

  tearDown(() => dir.delete(recursive: true));

  test('applyKey enables the cipher on a file database', () {
    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    applyKey(raw, "s3cret'key");
    expect(raw.select('PRAGMA cipher'), isNotEmpty);
    expect(raw.select('PRAGMA journal_mode').single.values.first, 'wal');
  });

  test('data written with one key is unreadable with another', () async {
    final db = VaultFlowDatabase(
      NativeDatabase(file, setup: (raw) => applyKey(raw, 'right')),
    );
    await db.settingsDao.setSetting('theme', 'dark');
    await db.close();

    // Plain open (no key) must not see a readable SQLite file.
    final plain = sqlite3.open(file.path);
    expect(
      () => plain.select('SELECT count(*) FROM sqlite_master'),
      throwsA(isA<SqliteException>()),
    );
    plain.close();

    expect(
      () => applyKey(sqlite3.open(file.path), 'wrong'),
      throwsA(isA<SqliteException>()),
    );

    final reopened = VaultFlowDatabase(
      NativeDatabase(file, setup: (raw) => applyKey(raw, 'right')),
    );
    addTearDown(reopened.close);
    expect(await reopened.settingsDao.getSetting('theme'), 'dark');
    expect(await reopened.settingsDao.getSyncState('pull_cursor'), isNull);
  });
}
