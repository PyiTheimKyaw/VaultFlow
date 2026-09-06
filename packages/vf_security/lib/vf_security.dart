/// Secure storage, biometric gate, app lock controller, PIN vault.
///
/// Phase 2 ships the minimal slice the database opener needs: a
/// `SecureStore` abstraction and the `DbKeyProvider` that keeps the SQLite
/// passphrase in the platform keychain. Biometrics, PIN and the lock
/// controller arrive with Phase 3.
library;

export 'src/db_key_provider.dart';
export 'src/secure_store.dart';
export 'src/vf_security_version.dart';
