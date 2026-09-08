import 'dart:io';

import 'package:postgres/postgres.dart' show Sql;
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Runs only when `TEST_DATABASE_URL` points at a disposable Postgres.
void main() {
  final url = Platform.environment['TEST_DATABASE_URL'];
  final skip = url == null || url.isEmpty
      ? 'set TEST_DATABASE_URL to run Postgres integration tests'
      : null;

  late Database db;
  late SyncService service;
  late String userId;

  setUpAll(() async {
    if (skip != null) return;
    db = Database.fromUrl(url!);
    await db.migrate(Directory('migrations'));
    await db.pool.execute(
      'TRUNCATE changes, applied_ops, notes, documents, folders, '
      'refresh_tokens, devices, users',
    );
    userId = VfId.next();
    await db.pool.execute(
      Sql.named(
        'INSERT INTO users (id, email, password_hash) VALUES (@id, @email, @h)',
      ),
      parameters: {'id': userId, 'email': 'sync@example.com', 'h': 'x'},
    );
    service = SyncService(store: PostgresSyncStore(db.pool));
  });

  tearDownAll(() async {
    if (skip == null) await db.close();
  });

  test('push, conflict, idempotent replay and feed on Postgres', () async {
    final noteId = VfId.next();
    final now = DateTime.now().toUtc().toIso8601String();
    SyncOpRequest op(SyncOp kind, int base, String title, String clientOpId) =>
        SyncOpRequest(
          clientOpId: clientOpId,
          entityType: EntityType.note,
          entityId: noteId,
          op: kind,
          baseVersion: base,
          payload: {
            'title': title,
            'body': 'b',
            'created_at': now,
            'updated_at': now,
          },
        );

    final created = await service.push(
      userId: userId,
      deviceId: 'dev-a',
      request: PushRequest(
        deviceId: 'dev-a',
        ops: [op(SyncOp.create, 0, 'v1', 'op1')],
      ),
    );
    expect(created.results.single.newVersion, 1);

    final replay = await service.push(
      userId: userId,
      deviceId: 'dev-a',
      request: PushRequest(
        deviceId: 'dev-a',
        ops: [op(SyncOp.create, 0, 'v1', 'op1')],
      ),
    );
    expect(replay.results.single.toJson(), created.results.single.toJson());

    final conflict = await service.push(
      userId: userId,
      deviceId: 'dev-b',
      request: PushRequest(
        deviceId: 'dev-b',
        ops: [op(SyncOp.update, 0, 'stale', 'op2')],
      ),
    );
    expect(conflict.results.single.status, SyncOpStatus.conflict);
    expect(conflict.results.single.remote!['title'], 'v1');

    final feedForB = await service.changes(
      userId: userId,
      since: 0,
      limit: 10,
      excludeDeviceId: 'dev-b',
    );
    expect(feedForB.changes.single.entityId, noteId);
    expect(feedForB.changes.single.payload['title'], 'v1');
    expect(feedForB.nextCursor, greaterThan(0));
  }, skip: skip);
}
