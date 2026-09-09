import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers.dart';

void main() {
  late FakeTransferServer server;
  late Device a;

  setUp(() async {
    server = FakeTransferServer();
    a = await Device.create(server, name: 'A');
  });

  tearDown(() async {
    await a.close();
    await server.dispose();
  });

  test(
    'uploads in parallel chunks, completes, and releases the blocked create',
    () async {
      final file = await a.makeFile(
        'big.bin',
        1000 * 1024,
      ); // 16 chunks of 64 KiB
      final (doc, sessionId) = await a.importFile(file);
      expect((await a.outbox()).single.state, OutboxState.blocked);

      await a.engine.drain();
      final session = await a.session(sessionId);
      expect(session.state, 'completed');
      expect(session.bytesDone, 1000 * 1024);
      expect(server.storage.partWrites.length, 16);
      expect(server.storage.partWrites.values.toSet(), {
        1,
      }, reason: 'each part once');

      final stored = (await a.vault.getDocument(doc.id))!;
      expect(stored.storageKey, isNotNull);
      expect(
        await server.uploads.ownsBlob(a.userId, stored.storageKey!),
        isTrue,
      );

      final create = (await a.outbox()).single;
      expect(create.state, OutboxState.pending, reason: 'unblocked');
      expect(create.payload['storage_key'], stored.storageKey);
      expect(
        a.engine.progress.value,
        isEmpty,
        reason: 'progress cleared when done',
      );
    },
  );

  test(
    'dropped chunk requests are retried without duplicating parts',
    () async {
      server.failNextChunkPuts = 5;
      final file = await a.makeFile('flaky.bin', 300 * 1024);
      final (_, sessionId) = await a.importFile(file);
      await a.engine.drain();
      expect((await a.session(sessionId)).state, 'completed');
      expect(server.storage.partWrites.values.toSet(), {1});
      expect(server.chunkPuts, greaterThan(5));
    },
  );

  test('a kill mid-upload resumes from the persisted chunk state', () async {
    final file = await a.makeFile('resume.bin', 640 * 1024); // 10 chunks
    // Let exactly three parts through, then freeze the server.
    final gate = Completer<void>();
    var released = 0;
    server.storage.beforePart = (index) async {
      if (released < 3) {
        released++;
        return;
      }
      await gate.future;
    };
    final (doc, sessionId) = await a.importFile(file);
    while ((await a.db.transfersDao.getChunks(sessionId))
            .where((c) => c.state == 'done')
            .length <
        3) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final doneBefore = (await a.db.transfersDao.getChunks(sessionId))
        .where((c) => c.state == 'done')
        .map((c) => c.idx)
        .toSet();
    expect(doneBefore, hasLength(3));

    // "Kill" the app: dispose the engine while requests are in flight.
    await a.close(keepDb: true);
    server.storage.beforePart = null;
    gate.complete();

    // Restart on the same database.
    final b = await Device.create(
      server,
      name: 'A2',
      db: a.db,
      cacheDir: a.cacheDir,
    );
    server.sessions.addAll(server.sessions); // same user, new token
    expect((await b.session(sessionId)).state, isIn(['queued', 'running']));
    await b.engine.drain();
    final resumed = await b.session(sessionId);
    expect(resumed.state, 'completed', reason: resumed.lastError);
    for (final idx in doneBefore) {
      expect(
        server.storage.partWrites[idx],
        1,
        reason: 'part $idx not re-sent',
      );
    }
    expect((await b.vault.getDocument(doc.id))!.storageKey, isNotNull);
    await b.close();
  });

  test('identical content is deduplicated instantly', () async {
    final first = await a.makeFile('one.bin', 200 * 1024, seed: 9);
    final second = await a.makeFile('two.bin', 200 * 1024, seed: 9);
    final (_, s1) = await a.importFile(first);
    await a.engine.drain();
    final putsAfterFirst = server.chunkPuts;
    final (doc2, s2) = await a.importFile(second);
    await a.engine.drain();
    expect((await a.session(s2)).state, 'completed');
    expect(server.chunkPuts, putsAfterFirst, reason: 'no chunk sent');
    expect((await a.vault.getDocument(doc2.id))!.storageKey, isNotNull);
    expect((await a.session(s1)).state, 'completed');
    expect(
      await a.db.settingsDao.getSyncState('dedupe_saved_bytes'),
      '${200 * 1024}',
    );
  });

  test('a session the server forgot restarts from zero', () async {
    final file = await a.makeFile('expire.bin', 200 * 1024);
    final gate = Completer<void>();
    server.storage.beforePart = (_) => gate.future;
    final (_, sessionId) = await a.importFile(file);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await a.engine.pause(sessionId);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    server.storage.beforePart = null;
    // Server-side expiry: 25 hours pass.
    server.clock.advance(const Duration(hours: 25));
    await a.engine.resume(sessionId);
    await a.engine.drain();
    expect((await a.session(sessionId)).state, 'completed');
  });

  test('a permanent server rejection parks the session as failed', () async {
    final file = await a.makeFile('reject.bin', 10 * 1024);
    // Hold the server so the upload cannot finish before we intervene.
    final gate = Completer<void>();
    server.storage.beforePart = (_) => gate.future;
    final (doc, sessionId) = await a.importFile(file);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await a.engine.pause(sessionId);
    gate.complete();
    server.storage.beforePart = null;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Removing the document row is a non-retryable error for the worker.
    await a.db.customStatement("DELETE FROM documents WHERE id = '${doc.id}'");
    await a.engine.resume(sessionId);
    await a.engine.drain();
    final session = await a.session(sessionId);
    expect(session.state, 'failed');
    expect(session.lastError, contains('deleted'));
  });
}
