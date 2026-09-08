import 'dart:io';

import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';

/// Runs only when `TEST_DATABASE_URL` points at a disposable Postgres.
void main() {
  final url = Platform.environment['TEST_DATABASE_URL'];
  final skip = url == null || url.isEmpty
      ? 'set TEST_DATABASE_URL to run Postgres integration tests'
      : null;

  late Database db;
  late PostgresAuthStore store;

  setUpAll(() async {
    if (skip != null) return;
    db = Database.fromUrl(url!);
    await db.migrate(Directory('migrations'));
    await db.pool.execute('TRUNCATE refresh_tokens, devices, users');
    store = PostgresAuthStore(db.pool);
  });

  tearDownAll(() async {
    if (skip == null) await db.close();
  });

  test('user, device and token round trip with rotation', () async {
    final now = DateTime.now().toUtc();
    final user = (await store.createUser(
      UserRecord(
        id: VfId.next(),
        email: 'pg@example.com',
        passwordHash: 'h',
        createdAt: now,
      ),
    ))!;
    expect(await store.createUser(user), isNull, reason: 'duplicate email');
    expect((await store.findUserByEmail('PG@example.com'))!.id, user.id);

    final device = DeviceRecord(
      id: VfId.next(),
      userId: user.id,
      name: 'd',
      platform: 'linux',
      lastSeenAt: now,
    );
    await store.upsertDevice(device);
    final token = RefreshTokenRecord(
      id: VfId.next(),
      userId: user.id,
      deviceId: device.id,
      familyId: VfId.next(),
      tokenHash: 'hash1',
      expiresAt: now.add(const Duration(days: 1)),
      createdAt: now,
    );
    await store.insertRefreshToken(token);
    final replacement = RefreshTokenRecord(
      id: VfId.next(),
      userId: user.id,
      deviceId: device.id,
      familyId: token.familyId,
      tokenHash: 'hash2',
      expiresAt: now.add(const Duration(days: 1)),
      createdAt: now,
    );
    await store.rotateRefreshToken(token.id, replacement);
    expect(
      (await store.findRefreshTokenByHash('hash1'))!.replacedBy,
      replacement.id,
    );
    await store.revokeFamily(token.familyId, now);
    expect((await store.findRefreshTokenByHash('hash2'))!.revokedAt, isNotNull);
  }, skip: skip);
}
