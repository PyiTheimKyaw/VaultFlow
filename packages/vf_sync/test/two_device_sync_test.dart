import 'package:flutter_test/flutter_test.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers.dart';

/// Two devices, one server: edits made offline on both converge, and a
/// concurrent edit to the same note produces exactly one conflict.
void main() {
  late FakeSyncServer server;
  late Device a;
  late Device b;

  setUp(() async {
    server = FakeSyncServer();
    a = await Device.create(server, name: 'Mac');
    b = await Device.create(server, name: 'Phone');
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<List<(String, String, String, int)>> fingerprint(Device d) async =>
      (await d.liveNotes())
          .map((n) => (n.id, n.title, n.body, n.version))
          .toList()
        ..sort((x, y) => x.$1.compareTo(y.$1));

  test('a note created on A appears on B and edits flow both ways', () async {
    final note = a.newNote('Groceries', body: 'milk');
    await a.notes.createNote(note);
    final ra = await a.engine.syncNow();
    expect(ra.push.applied, 1);

    final rb = await b.engine.syncNow();
    expect(rb.pull.applied, 1);
    final onB = (await b.notes.getNote(note.id))!;
    expect(onB.title, 'Groceries');
    expect(onB.version, 1);
    expect(onB.syncStatus, SyncStatus.synced);

    await b.notes.saveNote(
      note.id,
      title: 'Groceries',
      body: 'milk, eggs',
      now: b.clock.now(),
    );
    await b.engine.syncNow();
    await a.engine.syncNow();
    expect((await a.notes.getNote(note.id))!.body, 'milk, eggs');
    expect((await a.notes.getNote(note.id))!.version, 2);
    expect(await fingerprint(a), await fingerprint(b));
  });

  test('concurrent offline edits produce exactly one conflict, resolvable three ways', () async {
    final note = a.newNote('Plan', body: 'v1');
    await a.notes.createNote(note);
    await a.engine.syncNow();
    await b.engine.syncNow();

    // Both go offline and edit the same note.
    await a.notes.saveNote(
      note.id,
      title: 'Plan',
      body: 'A edit',
      now: a.clock.now(),
    );
    await b.notes.saveNote(
      note.id,
      title: 'Plan',
      body: 'B edit',
      now: b.clock.now(),
    );

    // A reconnects first and wins.
    expect((await a.engine.syncNow()).push.applied, 1);

    // B reconnects: its push conflicts, its pull skips the entity.
    final rb = await b.engine.syncNow();
    expect(rb.push.conflicts, 1);
    expect(
      rb.pull.skipped,
      1,
      reason: "A's update is skipped while the conflict is open",
    );
    final conflicts = await b.conflicts();
    expect(conflicts, hasLength(1));
    expect(conflicts.single.localSnapshot['body'], 'B edit');
    expect(conflicts.single.remoteSnapshot['body'], 'A edit');
    expect(conflicts.single.remoteVersion, 2);
    expect((await b.notes.getNote(note.id))!.syncStatus, SyncStatus.conflicted);
    expect(
      (await b.notes.getNote(note.id))!.body,
      'B edit',
      reason: 'local kept until resolved',
    );

    // Syncing again does not create a second conflict.
    await b.engine.syncNow();
    expect(await b.conflicts(), hasLength(1));

    // Keep both: A's version replaces B's row, B's edit lives on as a copy.
    final result = await b.engine.resolveConflict(
      conflicts.single.id,
      ConflictResolution.keepBoth,
    );
    expect(result.isOk, isTrue);
    expect(await b.conflicts(), isEmpty);
    final bNotes = await b.liveNotes();
    expect(bNotes, hasLength(2));
    final original = bNotes.firstWhere((n) => n.id == note.id);
    expect(original.body, 'A edit');
    expect(original.version, 2);
    expect(original.syncStatus, SyncStatus.synced);
    final copy = bNotes.firstWhere((n) => n.id != note.id);
    expect(copy.title, startsWith('Plan (Conflicted copy, Phone, '));
    expect(copy.body, 'B edit');

    await b.engine.syncNow();
    await a.engine.syncNow();
    expect(await fingerprint(a), await fingerprint(b));
    expect(await a.liveNotes(), hasLength(2));
  });

  test('keep local re-bases and wins on the next push', () async {
    final note = a.newNote('Doc', body: 'v1');
    await a.notes.createNote(note);
    await a.engine.syncNow();
    await b.engine.syncNow();
    await a.notes.saveNote(
      note.id,
      title: 'Doc',
      body: 'A',
      now: a.clock.now(),
    );
    await b.notes.saveNote(
      note.id,
      title: 'Doc',
      body: 'B',
      now: b.clock.now(),
    );
    await a.engine.syncNow();
    await b.engine.syncNow();
    final conflict = (await b.conflicts()).single;

    await b.engine.resolveConflict(conflict.id, ConflictResolution.keepLocal);
    final pending = (await b.notes.getNote(note.id))!;
    expect(pending.syncStatus, SyncStatus.pending);
    expect(pending.version, 2, reason: 're-based on the remote version');
    final rb = await b.engine.syncNow();
    expect(rb.push.applied, 1);
    expect(rb.push.conflicts, 0);

    await a.engine.syncNow();
    expect((await a.notes.getNote(note.id))!.body, 'B');
    expect((await a.notes.getNote(note.id))!.version, 3);
    expect(await fingerprint(a), await fingerprint(b));
  });

  test('keep remote discards the local edit', () async {
    final note = a.newNote('N', body: 'v1');
    await a.notes.createNote(note);
    await a.engine.syncNow();
    await b.engine.syncNow();
    await a.notes.saveNote(note.id, title: 'N', body: 'A', now: a.clock.now());
    await b.notes.saveNote(note.id, title: 'N', body: 'B', now: b.clock.now());
    await a.engine.syncNow();
    await b.engine.syncNow();
    final conflict = (await b.conflicts()).single;
    await b.engine.resolveConflict(conflict.id, ConflictResolution.keepRemote);
    final onB = (await b.notes.getNote(note.id))!;
    expect(onB.body, 'A');
    expect(onB.syncStatus, SyncStatus.synced);
    expect(await b.outbox(), isEmpty);
  });

  test('deletes and folder moves converge', () async {
    final folder = Folder(
      id: 'f-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Shared',
      createdAt: a.clock.now(),
      updatedAt: a.clock.now(),
    );
    // Folder ids must be UUIDs for the server; build one properly.
    final f = folder.copyWith(id: a.newNote('x').id);
    await a.vault.createFolder(f);
    final note = a.newNote('inside');
    await a.notes.createNote(note);
    await a.engine.syncNow();
    await b.engine.syncNow();
    expect(await b.vault.getFolder(f.id), isNotNull);

    await b.notes.moveNote(note.id, f.id, b.clock.now());
    await b.vault.deleteFolder(f.id, b.clock.now());
    await b.engine.syncNow();
    await a.engine.syncNow();
    expect(await a.vault.getFolder(f.id), isNull);
    expect((await a.notes.getNote(note.id))!.isDeleted, isTrue);
    expect(await fingerprint(a), await fingerprint(b));
  });

  test('a crash mid-push is recovered and never double-applies', () async {
    final note = a.newNote('crash');
    await a.notes.createNote(note);
    final row = (await a.outbox()).single;
    await a.db.outboxDao.markInFlight([row.id]);
    // The push reached the server but the response was lost.
    await a.engine.push.api.push(
      PushRequestFixture.single(a.engine.deviceId, row),
    );
    // Restart: recovery releases the row, the retry replays the same
    // client_op_id and the server returns the stored result.
    await a.engine.recover();
    final report = await a.engine.syncNow();
    expect(report.push.applied, 1);
    expect(server.store.changes, hasLength(1));
    expect((await a.notes.getNote(note.id))!.version, 1);
  });
}
