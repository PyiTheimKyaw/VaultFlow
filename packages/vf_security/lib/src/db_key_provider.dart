import 'dart:convert';
import 'dart:math';

import 'package:vf_security/src/secure_store.dart';

/// Owns the passphrase that encrypts the local database.
///
/// The key is 32 random bytes generated once on first launch, stored in the
/// platform keychain via [SecureStore], and never leaves the device. Losing
/// the keychain entry (e.g. uninstall) makes the database unreadable, which
/// is the intended behaviour: the server holds the canonical copy.
final class DbKeyProvider {
  DbKeyProvider(this._store, {Random? random})
    : _random = random ?? Random.secure();

  static const String storageKey = 'vf.db_key.v1';
  static const int keyBytes = 32;

  final SecureStore _store;
  final Random _random;

  /// Returns the existing key, creating and persisting one if needed.
  Future<String> getOrCreate() async {
    final existing = await _store.read(storageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(keyBytes, (_) => _random.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _store.write(storageKey, key);
    return key;
  }

  /// Forgets the key. Only call after deleting the database file.
  Future<void> reset() => _store.delete(storageKey);
}
