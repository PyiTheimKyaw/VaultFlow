/// Helpers for tests on native platforms (uses `dart:ffi`; not for web).
library;

import 'package:drift/native.dart';
import 'package:vf_database/src/database.dart';

/// An empty in-memory database with the full schema applied.
VaultFlowDatabase openInMemoryDatabase() =>
    VaultFlowDatabase(NativeDatabase.memory());
