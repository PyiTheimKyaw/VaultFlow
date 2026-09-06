import 'package:vf_database/src/connection/open_database_stub.dart'
    if (dart.library.io) 'package:vf_database/src/connection/open_database_native.dart'
    if (dart.library.js_interop) 'package:vf_database/src/connection/open_database_web.dart'
    as impl;
import 'package:vf_database/src/database.dart';

/// Supplies the database passphrase. On native platforms the app provides
/// one backed by secure storage (`vf_security`); on the web it is ignored
/// because the wasm build has no cipher (documented limitation).
typedef DatabaseKeyLoader = Future<String> Function();

/// Opens (or creates) the on-device database named [name].
///
/// * Native: SQLite3MultipleCiphers file under the app-support directory,
///   encrypted with the key from [keyLoader]. Throws [StateError] if the
///   bundled SQLite has no cipher, so plaintext is never written silently.
/// * Web: `sqlite3.wasm` + `drift_worker.js` from the `web/` folder, stored
///   in OPFS or IndexedDB depending on browser support.
Future<VaultFlowDatabase> openVaultFlowDatabase({
  required DatabaseKeyLoader keyLoader,
  String name = 'vaultflow',
}) => impl.openDatabase(name: name, keyLoader: keyLoader);
