import 'package:postgres/postgres.dart';
import 'package:vaultflow_server/auth/auth_store.dart';
import 'package:vaultflow_server/auth/models.dart';

/// [AuthStore] on Postgres (schema in `migrations/0001_init.sql`).
class PostgresAuthStore implements AuthStore {
  PostgresAuthStore(this._session);

  final Session _session;

  UserRecord _user(ResultRow r) {
    final m = r.toColumnMap();
    return UserRecord(
      id: m['id'] as String,
      email: m['email'] as String,
      passwordHash: m['password_hash'] as String,
      createdAt: m['created_at'] as DateTime,
    );
  }

  RefreshTokenRecord _token(ResultRow r) {
    final m = r.toColumnMap();
    return RefreshTokenRecord(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      deviceId: m['device_id'] as String,
      familyId: m['family_id'] as String,
      tokenHash: m['token_hash'] as String,
      expiresAt: m['expires_at'] as DateTime,
      createdAt: m['created_at'] as DateTime,
      revokedAt: m['revoked_at'] as DateTime?,
      replacedBy: m['replaced_by'] as String?,
    );
  }

  @override
  Future<UserRecord?> createUser(UserRecord user) async {
    final result = await _session.execute(
      Sql.named('''
        INSERT INTO users (id, email, password_hash, created_at)
        VALUES (@id, @email, @hash, @created)
        ON CONFLICT (email) DO NOTHING
        RETURNING id, email::text, password_hash, created_at'''),
      parameters: {
        'id': user.id,
        'email': user.email,
        'hash': user.passwordHash,
        'created': user.createdAt,
      },
    );
    return result.isEmpty ? null : _user(result.first);
  }

  @override
  Future<UserRecord?> findUserByEmail(String email) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT id, email::text, password_hash, created_at FROM users '
        'WHERE email = @email',
      ),
      parameters: {'email': email},
    );
    return result.isEmpty ? null : _user(result.first);
  }

  @override
  Future<UserRecord?> findUserById(String id) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT id, email::text, password_hash, created_at FROM users '
        'WHERE id = @id',
      ),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : _user(result.first);
  }

  @override
  Future<DeviceRecord?> findDevice(String id) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT id, user_id, name, platform, last_seen_at FROM devices '
        'WHERE id = @id',
      ),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    final m = result.first.toColumnMap();
    return DeviceRecord(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      name: m['name'] as String,
      platform: m['platform'] as String,
      lastSeenAt: m['last_seen_at'] as DateTime,
    );
  }

  @override
  Future<void> upsertDevice(DeviceRecord device) => _session.execute(
    Sql.named('''
      INSERT INTO devices (id, user_id, name, platform, last_seen_at)
      VALUES (@id, @user, @name, @platform, @seen)
      ON CONFLICT (id) DO UPDATE
        SET name = EXCLUDED.name, platform = EXCLUDED.platform,
            last_seen_at = EXCLUDED.last_seen_at'''),
    parameters: {
      'id': device.id,
      'user': device.userId,
      'name': device.name,
      'platform': device.platform,
      'seen': device.lastSeenAt,
    },
  );

  @override
  Future<void> insertRefreshToken(RefreshTokenRecord token) =>
      _insertToken(_session, token);

  Future<void> _insertToken(Session s, RefreshTokenRecord t) => s.execute(
    Sql.named('''
      INSERT INTO refresh_tokens
        (id, user_id, device_id, family_id, token_hash, expires_at, created_at)
      VALUES (@id, @user, @device, @family, @hash, @expires, @created)'''),
    parameters: {
      'id': t.id,
      'user': t.userId,
      'device': t.deviceId,
      'family': t.familyId,
      'hash': t.tokenHash,
      'expires': t.expiresAt,
      'created': t.createdAt,
    },
  );

  @override
  Future<RefreshTokenRecord?> findRefreshTokenByHash(String hash) async {
    final result = await _session.execute(
      Sql.named('SELECT * FROM refresh_tokens WHERE token_hash = @hash'),
      parameters: {'hash': hash},
    );
    return result.isEmpty ? null : _token(result.first);
  }

  @override
  Future<void> rotateRefreshToken(
    String oldId,
    RefreshTokenRecord replacement,
  ) async {
    Future<void> run(Session s) async {
      await s.execute(
        Sql.named(
          'UPDATE refresh_tokens SET replaced_by = @new WHERE id = @old',
        ),
        parameters: {'new': replacement.id, 'old': oldId},
      );
      await _insertToken(s, replacement);
    }

    final session = _session;
    if (session is Pool) {
      await session.runTx(run);
    } else {
      await run(session);
    }
  }

  @override
  Future<void> revokeToken(String id, DateTime at) => _session.execute(
    Sql.named(
      'UPDATE refresh_tokens SET revoked_at = @at '
      'WHERE id = @id AND revoked_at IS NULL',
    ),
    parameters: {'at': at, 'id': id},
  );

  @override
  Future<void> revokeFamily(String familyId, DateTime at) => _session.execute(
    Sql.named(
      'UPDATE refresh_tokens SET revoked_at = @at '
      'WHERE family_id = @family AND revoked_at IS NULL',
    ),
    parameters: {'at': at, 'family': familyId},
  );

  @override
  Future<void> revokeDevice(String deviceId, DateTime at) => _session.execute(
    Sql.named(
      'UPDATE refresh_tokens SET revoked_at = @at '
      'WHERE device_id = @device AND revoked_at IS NULL',
    ),
    parameters: {'at': at, 'device': deviceId},
  );
}
