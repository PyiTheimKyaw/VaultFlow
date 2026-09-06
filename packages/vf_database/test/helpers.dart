import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

/// Everything a repository test needs, on a fresh in-memory database.
class Harness {
  Harness()
    : db = openInMemoryDatabase(),
      clock = FakeClock(DateTime.utc(2026, 9, 6, 10));

  final VaultFlowDatabase db;
  final FakeClock clock;
  int _ids = 0;

  late final vault = DriftVaultRepository(db);
  late final notes = DriftNotesRepository(db);
  late final outbox = DriftOutboxRepository(db);

  String nextId() => 'id-${++_ids}';

  Folder folder(String name, {String? parentId}) => Folder(
    id: nextId(),
    name: name,
    parentId: parentId,
    createdAt: clock.now(),
    updatedAt: clock.now(),
  );

  Document document(String name, {String? folderId}) => Document(
    id: nextId(),
    name: name,
    folderId: folderId,
    mimeType: 'text/plain',
    sizeBytes: 3,
    sha256: 'abc',
    createdAt: clock.now(),
    updatedAt: clock.now(),
  );

  Note note(String title, {String body = '', String? folderId}) => Note(
    id: nextId(),
    title: title,
    body: body,
    folderId: folderId,
    createdAt: clock.now(),
    updatedAt: clock.now(),
  );

  Future<List<OutboxEntry>> outboxEntries() => outbox.watchAll().first;

  Future<void> close() => db.close();
}
