import 'package:vaultflow_server/auth/auth_store.dart';
import 'package:vaultflow_server/auth/models.dart';
import 'package:vaultflow_server/auth/password_hasher.dart';
import 'package:vaultflow_server/auth/token_service.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Register, login, refresh and logout.
///
/// Refresh tokens rotate on every use. A token that has already been
/// rotated (or revoked) being presented again means it leaked, so the whole
/// family — every token descending from that login — is revoked.
class AuthService {
  AuthService({
    required this.store,
    required this.hasher,
    required this.tokens,
    required this.refreshTokenTtl,
    this.clock = const SystemClock(),
  });

  final AuthStore store;
  final PasswordHasher hasher;
  final TokenService tokens;
  final Duration refreshTokenTtl;
  final Clock clock;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const int minPasswordLength = 8;
  static const Set<String> platforms = {
    'android',
    'ios',
    'macos',
    'windows',
    'linux',
    'web',
  };

  Future<AuthTokens> register(CredentialsRequest request) async {
    final email = _normalizeEmail(request.email);
    if (request.password.length < minPasswordLength) {
      throw const ApiException.validation(
        'Password must be at least 8 characters',
        details: {'field': 'password'},
      );
    }
    _validateDevice(request);
    final now = clock.now();
    final user = await store.createUser(
      UserRecord(
        id: VfId.next(),
        email: email,
        passwordHash: await hasher.hash(request.password),
        createdAt: now,
      ),
    );
    if (user == null) {
      throw const ApiException(
        ApiErrorCode.emailTaken,
        'An account with this email already exists',
      );
    }
    final device = await _registerDevice(user.id, request, now);
    return await _issue(user, device, now);
  }

  Future<AuthTokens> login(CredentialsRequest request) async {
    final email = _normalizeEmail(request.email);
    _validateDevice(request);
    final user = await store.findUserByEmail(email);
    if (user == null) {
      // Verify against a dummy hash so timing does not reveal whether the
      // email exists.
      await hasher.verify(request.password, _dummyHash);
      throw const ApiException.unauthorized('Incorrect email or password');
    }
    if (!await hasher.verify(request.password, user.passwordHash)) {
      throw const ApiException.unauthorized('Incorrect email or password');
    }
    final now = clock.now();
    final device = await _registerDevice(user.id, request, now);
    return await _issue(user, device, now);
  }

  Future<AuthTokens> refresh(RefreshRequest request) async {
    final now = clock.now();
    final hash = TokenService.hashRefreshToken(request.refreshToken);
    final row = await store.findRefreshTokenByHash(hash);
    if (row == null) {
      throw const ApiException(
        ApiErrorCode.tokenRevoked,
        'Refresh token is not valid',
      );
    }
    if (!row.isActive) {
      // Reuse of a rotated or revoked token: treat as theft.
      await store.revokeFamily(row.familyId, now);
      throw const ApiException(
        ApiErrorCode.tokenRevoked,
        'Refresh token was already used; session revoked',
      );
    }
    if (row.deviceId != request.deviceId) {
      await store.revokeFamily(row.familyId, now);
      throw const ApiException(
        ApiErrorCode.tokenRevoked,
        'Refresh token does not belong to this device',
      );
    }
    if (!row.expiresAt.isAfter(now)) {
      await store.revokeToken(row.id, now);
      throw const ApiException(
        ApiErrorCode.tokenExpired,
        'Refresh token expired',
      );
    }
    final user = await store.findUserById(row.userId);
    if (user == null) throw const ApiException.unauthorized();

    final raw = tokens.newRefreshToken();
    final replacement = RefreshTokenRecord(
      id: VfId.next(),
      userId: row.userId,
      deviceId: row.deviceId,
      familyId: row.familyId,
      tokenHash: TokenService.hashRefreshToken(raw),
      expiresAt: now.add(refreshTokenTtl),
      createdAt: now,
    );
    await store.rotateRefreshToken(row.id, replacement);
    return AuthTokens(
      accessToken: tokens.signAccessToken(
        userId: user.id,
        deviceId: row.deviceId,
      ),
      refreshToken: raw,
      deviceId: row.deviceId,
      userId: user.id,
      expiresIn: tokens.accessTokenTtl.inSeconds,
    );
  }

  /// Revokes the token's whole family. Idempotent: unknown tokens succeed.
  Future<void> logout(RefreshRequest request) async {
    final row = await store.findRefreshTokenByHash(
      TokenService.hashRefreshToken(request.refreshToken),
    );
    if (row != null) await store.revokeFamily(row.familyId, clock.now());
  }

  Future<UserRecord?> userById(String id) => store.findUserById(id);

  Future<AuthTokens> _issue(
    UserRecord user,
    DeviceRecord device,
    DateTime now,
  ) async {
    final raw = tokens.newRefreshToken();
    await store.insertRefreshToken(
      RefreshTokenRecord(
        id: VfId.next(),
        userId: user.id,
        deviceId: device.id,
        familyId: VfId.next(),
        tokenHash: TokenService.hashRefreshToken(raw),
        expiresAt: now.add(refreshTokenTtl),
        createdAt: now,
      ),
    );
    return AuthTokens(
      accessToken: tokens.signAccessToken(userId: user.id, deviceId: device.id),
      refreshToken: raw,
      deviceId: device.id,
      userId: user.id,
      expiresIn: tokens.accessTokenTtl.inSeconds,
    );
  }

  Future<DeviceRecord> _registerDevice(
    String userId,
    CredentialsRequest request,
    DateTime now,
  ) async {
    final requested = request.deviceId;
    var id = VfId.next();
    if (requested != null && VfId.isValid(requested)) {
      final existing = await store.findDevice(requested);
      // Only reuse an id that is unknown or already belongs to this user.
      if (existing == null || existing.userId == userId) id = requested;
    }
    final device = DeviceRecord(
      id: id,
      userId: userId,
      name: request.deviceName.trim().isEmpty
          ? 'Unnamed device'
          : request.deviceName.trim(),
      platform: request.platform,
      lastSeenAt: now,
    );
    await store.upsertDevice(device);
    return device;
  }

  void _validateDevice(CredentialsRequest request) {
    if (!platforms.contains(request.platform)) {
      throw ApiException.validation(
        'Unknown platform; expected one of ${platforms.join(', ')}',
        details: const {'field': 'platform'},
      );
    }
  }

  String _normalizeEmail(String raw) {
    final email = raw.trim().toLowerCase();
    if (!_email.hasMatch(email)) {
      throw const ApiException.validation(
        'Enter a valid email address',
        details: {'field': 'email'},
      );
    }
    return email;
  }

  /// A real Argon2id hash of a random string; used to equalise login timing
  /// for unknown emails.
  static const String _dummyHash =
      r'$argon2id$v=19$m=256,t=1,p=1$'
      'AAAAAAAAAAAAAAAAAAAAAA'
      r'$'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
}
