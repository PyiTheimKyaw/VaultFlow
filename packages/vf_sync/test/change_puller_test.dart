import 'package:flutter_test/flutter_test.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers.dart';

void main() {
  late FakeSyncServer server;
  late Device a;
  late Device b;

  setUp(() async {
    server = FakeSyncServer();
    a = await Device.create(server, name: 'A');
    b = await Device.create(server, name: 'B');
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('pages through the feed and persists the cursor', () async {
    for (var i = 0; i < 7; i++) {
      await a.notes.createNote(a.newNote('n$i'));
    }
    await a.engine.syncNow();
    b.engine.pull.pageSize = 3;
    final report = await b.engine.pull.pullOnce();
    expect(report.applied, 7);
    expect(report.pages, 3);
    expect(await b.db.settingsDao.getPullCursor(), 7);

    // Nothing new: one empty page, cursor unchanged.
    final again = await b.engine.pull.pullOnce();
    expect(again.applied, 0);
    expect(again.pages, 1);
    expect(await b.db.settingsDao.getPullCursor(), 7);
  });

  test('a network error keeps the cursor at the last complete page', () async {
    await a.notes.createNote(a.newNote('x'));
    await a.engine.syncNow();
    server.offline = true;
    final report = await b.engine.pull.pullOnce();
    expect(report.isOk, isFalse);
    expect(await b.db.settingsDao.getPullCursor(), 0);
    server.offline = false;
    expect((await b.engine.pull.pullOnce()).applied, 1);
  });

  test(
    'remote changes to an entity with local unsynced edits are skipped',
    () async {
      final note = a.newNote('shared', body: '1');
      await a.notes.createNote(note);
      await a.engine.syncNow();
      await b.engine.syncNow();
      await b.notes.saveNote(
        note.id,
        title: 'shared',
        body: 'B',
        now: b.clock.now(),
      );
      await a.notes.saveNote(
        note.id,
        title: 'shared',
        body: 'A',
        now: a.clock.now(),
      );
      await a.engine.syncNow();

      final report = await b.engine.pull.pullOnce();
      expect(report.skipped, 1);
      expect((await b.notes.getNote(note.id))!.body, 'B');
      expect((await b.notes.getNote(note.id))!.syncStatus, SyncStatus.pending);
    },
  );

  test('pulled documents keep their local cache columns', () async {
    final doc = Document(
      id: a.newNote('x').id,
      name: 'a.txt',
      mimeType: 'text/plain',
      sizeBytes: 1,
      sha256: 'h',
      createdAt: a.clock.now(),
      updatedAt: a.clock.now(),
    );
    await a.vault.createDocument(doc);
    await a.engine.syncNow();
    await b.engine.syncNow();
    await b.vault.updateDocumentCache(
      doc.id,
      cacheState: CacheState.complete,
      localPath: '/b/a.txt',
    );
    await a.vault.renameDocument(doc.id, 'b.txt', a.clock.now());
    await a.engine.syncNow();
    await b.engine.syncNow();
    final onB = (await b.vault.getDocument(doc.id))!;
    expect(onB.name, 'b.txt');
    expect(onB.localPath, '/b/a.txt');
    expect(onB.cacheState, CacheState.complete);
  });
}
