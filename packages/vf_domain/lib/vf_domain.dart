/// Domain entities, repository interfaces and use cases (pure Dart).
///
/// Nothing here touches Drift, Flutter or the network; the app wires concrete
/// repositories from `vf_database` and runs use cases from its controllers.
library;

export 'package:vf_protocol/vf_protocol.dart' show EntityType, SyncOp;

export 'src/entities/conflict.dart';
export 'src/entities/document.dart';
export 'src/entities/folder.dart';
export 'src/entities/folder_contents.dart';
export 'src/entities/note.dart';
export 'src/entities/outbox_entry.dart';
export 'src/entities/sync_status.dart';
export 'src/repositories/notes_repository.dart';
export 'src/repositories/outbox_repository.dart';
export 'src/repositories/vault_repository.dart';
export 'src/usecases/item_name.dart';
export 'src/usecases/notes_use_cases.dart';
export 'src/usecases/search_use_cases.dart';
export 'src/usecases/vault_use_cases.dart';
export 'src/vf_domain_version.dart';
