import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());
  tearDown(() => h.close());

  test(
    'create then rename coalesces into one create with merged payload',
    () async {
      final folder = h.folder('Docs');
      await h.vault.createFolder(folder);
      h.clock.advance(const Duration(seconds: 5));
      await h.vault.renameFolder(folder.id, 'Documents', h.clock.now());

      final entries = await h.outboxEntries();
      expect(entries, hasLength(1));
      expect(entries.single.op, SyncOp.create);
      expect(entries.single.payload['name'], 'Documents');
      expect(entries.single.baseVersion, 0);
      expect(entries.single.state, OutboxState.pending);
    },
  );

  test('create then move keeps create with new parent', () async {
    final parent = h.folder('Parent');
    final child = h.folder('Child');
    await h.vault.createFolder(parent);
    await h.vault.createFolder(child);
    await h.vault.moveFolder(child.id, parent.id, h.clock.now());

    final entries = await h.outboxEntries();
    expect(entries, hasLength(2));
    final childOp = entries.firstWhere((e) => e.entityId == child.id);
    expect(childOp.op, SyncOp.create);
    expect(childOp.payload['parent_id'], parent.id);
  });

  test('create then delete drops both rows', () async {
    final folder = h.folder('Temp');
    await h.vault.createFolder(folder);
    await h.vault.deleteFolder(folder.id, h.clock.now());

    expect(await h.outboxEntries(), isEmpty);
    expect(await h.vault.getFolder(folder.id), isNull);
    final row = await h.db.foldersDao.getById(folder.id);
    expect(row!.deletedAt, isNotNull);
  });

  test('update + update on a synced entity yields one update', () async {
    final note = h.note('A');
    await h.notes.createNote(note);
    // Simulate a completed sync.
    await h.db.outboxDao.remove([(await h.outboxEntries()).single.id]);
    await h.db.notesDao.updateRow(
      note.id,
      const NotesCompanion(
        version: Value(3),
        syncStatus: Value(SyncStatus.synced),
      ),
    );

    await h.notes.saveNote(note.id, title: 'B', body: '1', now: h.clock.now());
    await h.notes.saveNote(note.id, title: 'C', body: '2', now: h.clock.now());

    final entries = await h.outboxEntries();
    expect(entries, hasLength(1));
    expect(entries.single.op, SyncOp.update);
    expect(entries.single.baseVersion, 3);
    expect(entries.single.payload['title'], 'C');
    expect(entries.single.payload['body'], '2');
    expect((await h.notes.getNote(note.id))!.syncStatus, SyncStatus.pending);
  });

  test('update then delete becomes delete', () async {
    final note = h.note('A');
    await h.notes.createNote(note);
    await h.db.outboxDao.remove([(await h.outboxEntries()).single.id]);
    await h.db.notesDao.updateRow(
      note.id,
      const NotesCompanion(
        version: Value(1),
        syncStatus: Value(SyncStatus.synced),
      ),
    );

    await h.notes.saveNote(note.id, title: 'B', body: '', now: h.clock.now());
    await h.notes.deleteNote(note.id, h.clock.now());

    final entries = await h.outboxEntries();
    expect(entries, hasLength(1));
    expect(entries.single.op, SyncOp.delete);
    expect(entries.single.payload, isEmpty);
    expect(entries.single.baseVersion, 1);
  });

  test('in-flight rows are never merged', () async {
    final note = h.note('A');
    await h.notes.createNote(note);
    final first = (await h.outboxEntries()).single;
    await h.db.outboxDao.markInFlight([first.id]);

    await h.notes.saveNote(note.id, title: 'B', body: '', now: h.clock.now());

    final entries = await h.outboxEntries();
    expect(entries, hasLength(2));
    expect(entries[0].state, OutboxState.inFlight);
    expect(entries[0].op, SyncOp.create);
    expect(entries[1].state, OutboxState.pending);
    expect(entries[1].op, SyncOp.update);
    expect(entries[1].clientOpId, isNot(entries[0].clientOpId));
  });

  test('move + move keeps the latest target only', () async {
    final a = h.folder('A');
    final b = h.folder('B');
    final doc = h.document('f.txt');
    await h.vault.createFolder(a);
    await h.vault.createFolder(b);
    await h.vault.createDocument(doc);
    await h.db.outboxDao.remove((await h.outboxEntries()).map((e) => e.id));

    await h.vault.moveDocument(doc.id, a.id, h.clock.now());
    await h.vault.moveDocument(doc.id, b.id, h.clock.now());

    final entries = await h.outboxEntries();
    expect(entries, hasLength(1));
    expect(entries.single.op, SyncOp.move);
    expect(entries.single.payload, {'folder_id': b.id});
  });

  test('pending count stream tracks the queue', () async {
    final counts = <int>[];
    final sub = h.outbox.watchPendingCount().listen(counts.add);
    await pumpEventQueue();
    await h.notes.createNote(h.note('x'));
    await pumpEventQueue();
    await h.notes.createNote(h.note('y'));
    await pumpEventQueue();
    await sub.cancel();
    expect(counts, [0, 1, 2]);
  });

  test('nextPending honours FIFO order and backoff', () async {
    await h.notes.createNote(h.note('1'));
    await h.notes.createNote(h.note('2'));
    final all = await h.outboxEntries();
    await h.db.outboxDao.scheduleRetry(
      all.first.id,
      attemptCount: 1,
      error: 'boom',
      nextAttemptAt: h.clock.now().add(const Duration(minutes: 5)),
      giveUp: false,
    );
    final ready = await h.db.outboxDao.nextPending(now: h.clock.now());
    expect(ready.map((r) => r.id), [all[1].id]);
    final later = await h.db.outboxDao.nextPending(
      now: h.clock.now().add(const Duration(minutes: 6)),
    );
    expect(later.map((r) => r.id), [all[0].id, all[1].id]);
  });

  test('outbox entry converts to a push request', () async {
    await h.notes.createNote(h.note('hello'));
    final entry = (await h.outboxEntries()).single;
    final request = entry.toRequest();
    expect(request.clientOpId, entry.clientOpId);
    expect(request.entityType, EntityType.note);
    expect(request.op, SyncOp.create);
    expect(request.payload['title'], 'hello');
  });

  test('scheduleRetry counts attempts and gives up into failed', () async {
    await h.notes.createNote(h.note('x'));
    final row = (await h.outboxEntries()).single;
    await h.db.outboxDao.scheduleRetry(
      row.id,
      attemptCount: 3,
      error: 'timeout',
      nextAttemptAt: h.clock.now().add(const Duration(seconds: 8)),
      giveUp: false,
    );
    var entry = (await h.outboxEntries()).single;
    expect(entry.state, OutboxState.pending);
    expect(entry.attemptCount, 3);
    expect(entry.lastError, 'timeout');
    expect(await h.db.outboxDao.nextPending(now: h.clock.now()), isEmpty);

    await h.db.outboxDao.scheduleRetry(
      row.id,
      attemptCount: 10,
      error: 'timeout',
      nextAttemptAt: h.clock.now(),
      giveUp: true,
    );
    entry = (await h.outboxEntries()).single;
    expect(entry.state, OutboxState.failed);
    expect(await h.db.outboxDao.watchFailedCount().first, 1);

    expect(await h.db.outboxDao.retryFailed(), 1);
    entry = (await h.outboxEntries()).single;
    expect(entry.state, OutboxState.pending);
    expect(entry.attemptCount, 0);
  });

  test('recoverInFlight releases rows left in flight by a crash', () async {
    await h.notes.createNote(h.note('x'));
    final row = (await h.outboxEntries()).single;
    await h.db.outboxDao.markInFlight([row.id]);
    expect(await h.db.outboxDao.recoverInFlight(), 1);
    expect((await h.outboxEntries()).single.state, OutboxState.pending);
  });
}
