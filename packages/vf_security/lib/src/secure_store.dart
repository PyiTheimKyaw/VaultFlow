import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small string key/value store backed by the platform keychain.
///
/// iOS/macOS: Keychain. Android: Keystore-encrypted preferences.
/// Windows: DPAPI. Linux: libsecret. Web: WebCrypto-wrapped localStorage
/// (documented as weaker; tokens are short-lived).
abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Removes every value this app stored. Used by "log out" and "wipe".
  Future<void> deleteAll();
}

/// [SecureStore] on `flutter_secure_storage`.
final class KeychainSecureStore implements SecureStore {
  KeychainSecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            // The data-protection keychain needs a keychain-access-groups
            // entitlement tied to a signing team; the legacy file keychain works
            // for sandboxed and ad-hoc signed builds alike.
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              usesDataProtectionKeychain: false,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// In-memory [SecureStore] for tests and previews.
final class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}
