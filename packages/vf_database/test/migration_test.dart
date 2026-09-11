import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_database/vf_database.dart';

import 'generated/schema.dart';

/// Every schema version ever shipped is dumped into `drift_schemas/` (see
/// `scripts/schema.sh`). This proves the current `onUpgrade` takes each of
/// them to the current schema and that user data survives the trip.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final from in GeneratedHelper.versions) {
    test(
      'upgrades from schema v$from to v${VaultFlowDatabase.currentSchemaVersion}',
      () async {
        final connection = await verifier.startAt(from);
        final db = VaultFlowDatabase(connection);
        addTearDown(db.close);
        await verifier.migrateAndValidate(
          db,
          VaultFlowDatabase.currentSchemaVersion,
        );
      },
    );
  }

  test('data written before the upgrade is still there afterwards', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      'INSERT INTO folders (id, name, version, created_at, updated_at, '
      "sync_status) VALUES ('f1', 'Tax', 0, '2026-01-01T00:00:00.000Z', "
      "'2026-01-01T00:00:00.000Z', 'pending')",
    );
    final db = VaultFlowDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(
      db,
      VaultFlowDatabase.currentSchemaVersion,
    );
    final rows = await db.foldersDao.getAllLive();
    expect(rows.single.name, 'Tax');
    // The migration ran inside the schema's transaction, so a failure could
    // never leave a half-upgraded file: drift sets the user version last.
    final version = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(version, VaultFlowDatabase.currentSchemaVersion);
  });
}
