import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Argon2id password hashing with PHC-formatted strings:
/// `$argon2id$v=19$m=<KiB>,t=<iterations>,p=<lanes>$<salt>$<hash>`.
///
/// Defaults follow the OWASP minimum (19 MiB, 2 iterations, 1 lane). The
/// parameters are stored with each hash, so they can be raised later
/// without invalidating existing users.
class PasswordHasher {
  PasswordHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    Random? random,
  }) : _random = random ?? Random.secure();

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final Random _random;

  static const int _saltLength = 16;

  Future<String> hash(String password) async {
    final salt = List<int>.generate(_saltLength, (_) => _random.nextInt(256));
    final digest = await _derive(
      password,
      salt,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
    return r'$argon2id$v=19$m='
        '$memoryKiB,t=$iterations,p=$parallelism'
        r'$'
        '${_b64(salt)}'
        r'$'
        '${_b64(digest)}';
  }

  /// Constant-time comparison against a PHC string; `false` for malformed
  /// input rather than throwing so callers cannot distinguish the cases.
  Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 6 || parts[1] != 'argon2id' || parts[2] != 'v=19') {
      return false;
    }
    final params = <String, int>{};
    for (final kv in parts[3].split(',')) {
      final pair = kv.split('=');
      if (pair.length != 2) return false;
      final value = int.tryParse(pair[1]);
      if (value == null) return false;
      params[pair[0]] = value;
    }
    final m = params['m'];
    final t = params['t'];
    final p = params['p'];
    if (m == null || t == null || p == null) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64Url.decode(base64Url.normalize(parts[4]));
      expected = base64Url.decode(base64Url.normalize(parts[5]));
    } on FormatException {
      return false;
    }
    final actual = await _derive(
      password,
      salt,
      memoryKiB: m,
      iterations: t,
      parallelism: p,
      hashLength: expected.length,
    );
    return constantTimeEquals(actual, expected);
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt, {
    required int memoryKiB,
    required int iterations,
    required int parallelism,
    required int hashLength,
  }) async {
    final algorithm = Argon2id(
      memory: memoryKiB,
      parallelism: parallelism,
      iterations: iterations,
      hashLength: hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return await key.extractBytes();
  }

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  /// Compares two byte lists without early exit.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
