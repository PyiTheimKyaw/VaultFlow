/// Drift local database: schema, DAOs, migrations, encrypted openers.
///
/// Import `package:vf_database/testing.dart` for in-memory databases in
/// tests; this library stays free of `dart:ffi` so it compiles on the web.
library;

export 'src/connection/open_database.dart';
export 'src/daos/conflicts_dao.dart';
export 'src/daos/documents_dao.dart';
export 'src/daos/folders_dao.dart';
export 'src/daos/notes_dao.dart';
export 'src/daos/outbox_dao.dart';
export 'src/daos/settings_dao.dart';
export 'src/daos/transfers_dao.dart';
export 'src/database.dart';
export 'src/repositories/drift_notes_repository.dart';
export 'src/repositories/drift_outbox_repository.dart';
export 'src/repositories/drift_sync_repository.dart';
export 'src/repositories/drift_vault_repository.dart';
export 'src/repositories/mappers.dart';
export 'src/vf_database_version.dart';
