import 'package:vaultflow_server/auth/models.dart';

/// Persistence for users, devices and refresh tokens.
abstract interface class AuthStore {
  /// Returns `null` when the email is already taken.
  Future<UserRecord?> createUser(UserRecord user);

  Future<UserRecord?> findUserByEmail(String email);

  Future<UserRecord?> findUserById(String id);

  Future<DeviceRecord?> findDevice(String id);

  Future<void> upsertDevice(DeviceRecord device);

  Future<void> insertRefreshToken(RefreshTokenRecord token);

  Future<RefreshTokenRecord?> findRefreshTokenByHash(String hash);

  /// Marks [oldId] as replaced by [replacement] and stores the replacement,
  /// atomically.
  Future<void> rotateRefreshToken(String oldId, RefreshTokenRecord replacement);

  Future<void> revokeToken(String id, DateTime at);

  Future<void> revokeFamily(String familyId, DateTime at);

  /// Every active token for a device (used by logout-everywhere later).
  Future<void> revokeDevice(String deviceId, DateTime at);
}

/// Map-backed [AuthStore] for tests and for `dart_frog dev` without Postgres.
class InMemoryAuthStore implements AuthStore {
  final Map<String, UserRecord> users = {};
  final Map<String, DeviceRecord> devices = {};
  final Map<String, RefreshTokenRecord> tokens = {};

  @override
  Future<UserRecord?> createUser(UserRecord user) async {
    if (users.values.any(
      (u) => u.email.toLowerCase() == user.email.toLowerCase(),
    )) {
      return null;
    }
    users[user.id] = user;
    return user;
  }

  @override
  Future<UserRecord?> findUserByEmail(String email) async => users.values
      .where((u) => u.email.toLowerCase() == email.toLowerCase())
      .firstOrNull;

  @override
  Future<UserRecord?> findUserById(String id) async => users[id];

  @override
  Future<DeviceRecord?> findDevice(String id) async => devices[id];

  @override
  Future<void> upsertDevice(DeviceRecord device) async =>
      devices[device.id] = device;

  @override
  Future<void> insertRefreshToken(RefreshTokenRecord token) async =>
      tokens[token.id] = token;

  @override
  Future<RefreshTokenRecord?> findRefreshTokenByHash(String hash) async =>
      tokens.values.where((t) => t.tokenHash == hash).firstOrNull;

  @override
  Future<void> rotateRefreshToken(
    String oldId,
    RefreshTokenRecord replacement,
  ) async {
    tokens[oldId] = tokens[oldId]!.copyWith(replacedBy: replacement.id);
    tokens[replacement.id] = replacement;
  }

  @override
  Future<void> revokeToken(String id, DateTime at) async {
    final t = tokens[id];
    if (t != null && t.revokedAt == null) {
      tokens[id] = t.copyWith(revokedAt: at);
    }
  }

  @override
  Future<void> revokeFamily(String familyId, DateTime at) async {
    for (final t in tokens.values.toList()) {
      if (t.familyId == familyId && t.revokedAt == null) {
        tokens[t.id] = t.copyWith(revokedAt: at);
      }
    }
  }

  @override
  Future<void> revokeDevice(String deviceId, DateTime at) async {
    for (final t in tokens.values.toList()) {
      if (t.deviceId == deviceId && t.revokedAt == null) {
        tokens[t.id] = t.copyWith(revokedAt: at);
      }
    }
  }
}
