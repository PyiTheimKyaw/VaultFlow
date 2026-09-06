import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());
  tearDown(() => h.close());

  test('watchContents emits live children sorted by name', () async {
    final root = h.folder('zeta');
    await h.vault.createFolder(root);
    await h.vault.createFolder(h.folder('alpha'));
    await h.vault.createDocument(h.document('b.txt'));
    await h.vault.createDocument(h.document('a.txt'));
    await h.notes.createNote(h.note('note'));
    await h.notes.createNote(h.note('inner', folderId: root.id));

    final contents = await h.vault.watchContents(null).first;
    expect(contents.folders.map((f) => f.name), ['alpha', 'zeta']);
    expect(contents.documents.map((d) => d.name), ['a.txt', 'b.txt']);
    expect(contents.notes.map((n) => n.title), ['note']);

    final inner = await h.vault.watchContents(root.id).first;
    expect(inner.notes.map((n) => n.title), ['inner']);
    expect(inner.folders, isEmpty);
  });

  test('watchContents re-emits when a child changes', () async {
    final seen = <int>[];
    final sub = h.vault.watchContents(null).listen((c) => seen.add(c.length));
    await pumpEventQueue();
    await h.vault.createFolder(h.folder('a'));
    await pumpEventQueue();
    await h.notes.createNote(h.note('n'));
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1, 2]);
  });

  test('getAncestors returns the root-first chain', () async {
    final a = h.folder('A');
    final b = h.folder('B', parentId: a.id);
    final c = h.folder('C', parentId: b.id);
    for (final f in [a, b, c]) {
      await h.vault.createFolder(f);
    }
    final chain = await h.vault.getAncestors(c.id);
    expect(chain.map((f) => f.name), ['A', 'B', 'C']);
    expect(await h.vault.getAncestors('missing'), isEmpty);
  });

  test(
    'deleteFolder tombstones the whole subtree and queues deletes',
    () async {
      final a = h.folder('A');
      final b = h.folder('B', parentId: a.id);
      final doc = h.document('d', folderId: b.id);
      final note = h.note('n', folderId: a.id);
      await h.vault.createFolder(a);
      await h.vault.createFolder(b);
      await h.vault.createDocument(doc);
      await h.notes.createNote(note);
      // Pretend everything synced so deletes are real ops, not coalesced away.
      await h.db.outboxDao.remove((await h.outboxEntries()).map((e) => e.id));

      await h.vault.deleteFolder(a.id, h.clock.now());

      expect(await h.vault.getFolder(a.id), isNull);
      expect(await h.vault.getFolder(b.id), isNull);
      expect((await h.vault.getDocument(doc.id))!.isDeleted, isTrue);
      expect((await h.notes.getNote(note.id))!.isDeleted, isTrue);

      final entries = await h.outboxEntries();
      expect(entries.every((e) => e.op == SyncOp.delete), isTrue);
      expect(entries.map((e) => e.entityId).toSet(), {
        a.id,
        b.id,
        doc.id,
        note.id,
      });
      // Children are queued before their parent.
      final ids = entries.map((e) => e.entityId).toList();
      expect(ids.indexOf(b.id), lessThan(ids.indexOf(a.id)));
      expect((await h.vault.watchContents(null).first).isEmpty, isTrue);
    },
  );

  test('renaming a missing folder throws NotFoundFailure', () async {
    expect(
      () => h.vault.renameFolder('nope', 'x', h.clock.now()),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('a failed transaction leaves no partial rows', () async {
    final folder = h.folder('A');
    await h.vault.createFolder(folder);
    // Duplicate primary key fails inside the transaction: the outbox must
    // not gain a second row.
    await expectLater(h.vault.createFolder(folder), throwsA(anything));
    expect(await h.outboxEntries(), hasLength(1));
  });

  test('updateDocumentCache does not touch the outbox', () async {
    final doc = h.document('d');
    await h.vault.createDocument(doc);
    await h.db.outboxDao.remove((await h.outboxEntries()).map((e) => e.id));
    await h.vault.updateDocumentCache(
      doc.id,
      cacheState: CacheState.complete,
      localPath: '/tmp/d',
    );
    expect(await h.outboxEntries(), isEmpty);
    final saved = await h.vault.getDocument(doc.id);
    expect(saved!.localPath, '/tmp/d');
    expect(saved.isAvailableOffline, isTrue);
  });

  test(
    'timestamps survive the round trip with millisecond precision',
    () async {
      h.clock.set(DateTime.utc(2026, 9, 6, 10, 20, 30, 456));
      final folder = h.folder('T');
      await h.vault.createFolder(folder);
      final saved = await h.vault.getFolder(folder.id);
      expect(saved!.createdAt, DateTime.utc(2026, 9, 6, 10, 20, 30, 456));
      expect(saved.createdAt.isUtc, isTrue);
    },
  );
}
