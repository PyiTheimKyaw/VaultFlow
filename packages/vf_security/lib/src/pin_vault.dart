import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_security/src/secure_store.dart';

/// Outcome of a PIN check.
@immutable
sealed class PinVerifyResult {
  const PinVerifyResult();
}

final class PinOk extends PinVerifyResult {
  const PinOk();
}

final class PinWrong extends PinVerifyResult {
  const PinWrong({required this.remainingAttempts});
  final int remainingAttempts;
}

final class PinLockedOut extends PinVerifyResult {
  const PinLockedOut({required this.until});
  final DateTime until;
}

/// Stores an Argon2id hash of the PIN in the keychain and rate-limits
/// guesses: after [maxAttempts] failures the vault locks for [baseLockout],
/// doubling each round up to [maxLockout].
///
/// A PIN has little entropy, so the lockout is what actually protects it;
/// the hash parameters are kept moderate to stay fast on phones.
final class PinVault {
  PinVault(
    this._store, {
    this.clock = const SystemClock(),
    Random? random,
    this.maxAttempts = 5,
    this.baseLockout = const Duration(seconds: 30),
    this.maxLockout = const Duration(minutes: 15),
    this.memoryKiB = 8192,
    this.iterations = 2,
  }) : _random = random ?? Random.secure();

  static const String hashKey = 'vf.pin.hash.v1';
  static const String attemptsKey = 'vf.pin.attempts';
  static const String lockoutKey = 'vf.pin.lockout_until';
  static const String roundsKey = 'vf.pin.lockout_rounds';
  static const int minLength = 4;
  static const int maxLength = 8;

  final SecureStore _store;
  final Clock clock;
  final Random _random;
  final int maxAttempts;
  final Duration baseLockout;
  final Duration maxLockout;
  final int memoryKiB;
  final int iterations;

  Future<bool> get hasPin async => (await _store.read(hashKey)) != null;

  /// Sets or replaces the PIN. Throws [ValidationFailure] on bad input.
  Future<void> setPin(String pin) async {
    if (pin.length < minLength || pin.length > maxLength) {
      throw const ValidationFailure('PIN must be 4 to 8 digits', field: 'pin');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw const ValidationFailure(
        'PIN must contain digits only',
        field: 'pin',
      );
    }
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final hash = await _derive(pin, salt);
    await _store.write(
      hashKey,
      '${base64Url.encode(salt)}:${base64Url.encode(hash)}',
    );
    await _resetCounters();
  }

  Future<void> clear() async {
    await _store.delete(hashKey);
    await _resetCounters();
  }

  Future<PinVerifyResult> verify(String pin) async {
    final now = clock.now();
    final lockout = await _lockoutUntil();
    if (lockout != null && lockout.isAfter(now)) {
      return PinLockedOut(until: lockout);
    }
    final stored = await _store.read(hashKey);
    if (stored == null) return const PinWrong(remainingAttempts: 0);
    final parts = stored.split(':');
    final salt = base64Url.decode(parts[0]);
    final expected = base64Url.decode(parts[1]);
    final actual = await _derive(pin, salt);
    if (_constantTimeEquals(actual, expected)) {
      await _resetCounters();
      return const PinOk();
    }
    final attempts = (await _attempts()) + 1;
    if (attempts >= maxAttempts) {
      final rounds = int.tryParse(await _store.read(roundsKey) ?? '') ?? 0;
      var lockoutDuration = baseLockout * pow(2, rounds).toInt();
      if (lockoutDuration > maxLockout) lockoutDuration = maxLockout;
      final until = now.add(lockoutDuration);
      await _store.write(lockoutKey, until.toIso8601String());
      await _store.write(roundsKey, '${rounds + 1}');
      await _store.write(attemptsKey, '0');
      return PinLockedOut(until: until);
    }
    await _store.write(attemptsKey, '$attempts');
    return PinWrong(remainingAttempts: maxAttempts - attempts);
  }

  Future<int> _attempts() async =>
      int.tryParse(await _store.read(attemptsKey) ?? '') ?? 0;

  Future<DateTime?> _lockoutUntil() async {
    final raw = await _store.read(lockoutKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _resetCounters() async {
    await _store.delete(attemptsKey);
    await _store.delete(lockoutKey);
    await _store.delete(roundsKey);
  }

  Future<List<int>> _derive(String pin, List<int> salt) async {
    final key = await Argon2id(
      memory: memoryKiB,
      parallelism: 1,
      iterations: iterations,
      hashLength: 32,
    ).deriveKeyFromPassword(password: pin, nonce: salt);
    return await key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
