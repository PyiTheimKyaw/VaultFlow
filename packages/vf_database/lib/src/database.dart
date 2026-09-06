import 'package:drift/drift.dart';
import 'package:vf_database/src/converters.dart';
import 'package:vf_database/src/daos/conflicts_dao.dart';
import 'package:vf_database/src/daos/documents_dao.dart';
import 'package:vf_database/src/daos/folders_dao.dart';
import 'package:vf_database/src/daos/notes_dao.dart';
import 'package:vf_database/src/daos/outbox_dao.dart';
import 'package:vf_database/src/daos/settings_dao.dart';
import 'package:vf_database/src/daos/transfers_dao.dart';
import 'package:vf_database/src/tables.dart';
import 'package:vf_domain/vf_domain.dart';

export 'package:vf_database/src/tables.dart';

part 'database.g.dart';

/// The local SQLite database. Open it with `openVaultFlowDatabase` on a real
/// device or `openInMemoryDatabase` (from `testing.dart`) in tests.
@DriftDatabase(
  tables: [
    Folders,
    Documents,
    Notes,
    Conflicts,
    SyncOutbox,
    SyncState,
    TransferSessions,
    TransferChunks,
    AppSettings,
  ],
  daos: [
    FoldersDao,
    DocumentsDao,
    NotesDao,
    OutboxDao,
    ConflictsDao,
    TransfersDao,
    SettingsDao,
  ],
)
class VaultFlowDatabase extends _$VaultFlowDatabase {
  VaultFlowDatabase(super.e);

  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
      await _createNotesFts();
    },
    onUpgrade: (m, from, to) async {
      // Schema 1 is the first release; future versions add steps here and
      // Phase 7 tests every upgrade path.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders (parent_id) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_documents_folder ON documents (folder_id) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notes_folder ON notes (folder_id) '
      'WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_outbox_entity '
      'ON sync_outbox (entity_type, entity_id, state)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_outbox_state ON sync_outbox (state, id)',
    );
  }

  /// External-content FTS5 index over notes, kept in sync by triggers.
  Future<void> _createNotesFts() async {
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5( '
      "title, body, content='notes', content_rowid='rowid', "
      "tokenize='unicode61 remove_diacritics 2')",
    );
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, body)
          VALUES (new.rowid, new.title, new.body);
      END''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, body)
          VALUES ('delete', old.rowid, old.title, old.body);
      END''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, body)
          VALUES ('delete', old.rowid, old.title, old.body);
        INSERT INTO notes_fts(rowid, title, body)
          VALUES (new.rowid, new.title, new.body);
      END''');
  }
}
