import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:meta/meta.dart';
import 'package:vf_core/vf_core.dart';

/// Claims carried by a verified access token.
@immutable
class AccessClaims {
  const AccessClaims({required this.userId, required this.deviceId});

  final String userId;
  final String deviceId;
}

/// Why an access token was rejected.
enum AccessTokenError { expired, invalid }

class AccessTokenException implements Exception {
  const AccessTokenException(this.reason);
  final AccessTokenError reason;

  @override
  String toString() => 'AccessTokenException(${reason.name})';
}

/// Signs and verifies JWT access tokens; generates opaque refresh tokens.
///
/// Refresh tokens are 32 random bytes (base64url). Only their SHA-256 hash
/// is stored, so a database leak does not leak usable tokens.
class TokenService {
  TokenService({
    required String secret,
    required this.accessTokenTtl,
    this.clock = const SystemClock(),
    Random? random,
  }) : _key = SecretKey(secret),
       _random = random ?? Random.secure();

  static const String issuer = 'vaultflow';

  final SecretKey _key;
  final Duration accessTokenTtl;
  final Clock clock;
  final Random _random;

  String signAccessToken({required String userId, required String deviceId}) {
    final now = clock.now();
    final jwt = JWT({
      'sub': userId,
      'dev': deviceId,
      'typ': 'access',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(accessTokenTtl).millisecondsSinceEpoch ~/ 1000,
    }, issuer: issuer);
    return jwt.sign(_key);
  }

  AccessClaims verifyAccessToken(String token) {
    final JWT jwt;
    try {
      jwt = JWT.verify(token, _key, issuer: issuer, checkExpiresIn: false);
    } on JWTException {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    final payload = jwt.payload;
    if (payload is! Map || payload['typ'] != 'access') {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    final exp = payload['exp'];
    if (exp is! int || clock.now().millisecondsSinceEpoch ~/ 1000 >= exp) {
      throw const AccessTokenException(AccessTokenError.expired);
    }
    final sub = payload['sub'];
    final dev = payload['dev'];
    if (sub is! String || dev is! String) {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    return AccessClaims(userId: sub, deviceId: dev);
  }

  /// A short-lived token that authorises exactly one document download,
  /// carried in the URL so a browser can fetch it without headers.
  String signDownloadToken({
    required String userId,
    required String documentId,
    required Duration ttl,
  }) {
    final now = clock.now();
    return JWT({
      'sub': userId,
      'doc': documentId,
      'typ': 'download',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(ttl).millisecondsSinceEpoch ~/ 1000,
    }, issuer: issuer).sign(_key);
  }

  /// Returns the user id when [token] is a valid download token for
  /// [documentId].
  String verifyDownloadToken(String token, {required String documentId}) {
    final JWT jwt;
    try {
      jwt = JWT.verify(token, _key, issuer: issuer, checkExpiresIn: false);
    } on JWTException {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    final payload = jwt.payload;
    if (payload is! Map ||
        payload['typ'] != 'download' ||
        payload['doc'] != documentId) {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    final exp = payload['exp'];
    if (exp is! int || clock.now().millisecondsSinceEpoch ~/ 1000 >= exp) {
      throw const AccessTokenException(AccessTokenError.expired);
    }
    final sub = payload['sub'];
    if (sub is! String) {
      throw const AccessTokenException(AccessTokenError.invalid);
    }
    return sub;
  }

  /// A fresh opaque refresh token.
  String newRefreshToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String hashRefreshToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
