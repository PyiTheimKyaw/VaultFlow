import 'package:drift/wasm.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/src/database.dart';

const _log = Logger('vf_database');

/// Backends that write through synchronously (OPFS).
const Set<WasmStorageImplementation> _durable = {
  WasmStorageImplementation.opfsShared,
  WasmStorageImplementation.opfsLocks,
};

Future<VaultFlowDatabase> openDatabase({
  required String name,
  required Future<String> Function() keyLoader,
}) async {
  final result = await WasmDatabase.open(
    databaseName: name,
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  final chosen = result.chosenImplementation;
  final fields = {
    'chosen': chosen.name,
    'missing': result.missingFeatures.map((f) => f.name).join(','),
  };
  if (_durable.contains(chosen)) {
    _log.info('web storage backend selected', fields: fields);
  } else {
    // IndexedDB backends flush lazily: writes from the last few seconds can
    // be lost when the tab closes. Serve the app with
    // `Cross-Origin-Opener-Policy: same-origin` and
    // `Cross-Origin-Embedder-Policy: require-corp` to unlock OPFS.
    _log.warning(
      'web storage backend is not durable; serve with COOP/COEP headers',
      fields: fields,
    );
  }
  return VaultFlowDatabase(result.resolvedExecutor);
}
