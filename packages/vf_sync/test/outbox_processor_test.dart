import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_protocol/vf_protocol.dart';

import 'helpers.dart';

void main() {
  late FakeSyncServer server;
  late Device a;

  setUp(() async {
    server = FakeSyncServer();
    a = await Device.create(server, name: 'A');
  });

  tearDown(() => a.close());

  test('applied ops become synced with the server version', () async {
    final note = a.newNote('hello');
    await a.notes.createNote(note);
    final report = await a.engine.push.pushOnce();
    expect(report.applied, 1);
    expect(report.failure, isNull);
    expect(await a.outbox(), isEmpty);
    final saved = (await a.notes.getNote(note.id))!;
    expect(saved.version, 1);
    expect(saved.syncStatus, SyncStatus.synced);
    expect(server.store.changes.single.entityId, note.id);
  });

  test(
    'an edit made while the batch is in flight keeps the entity pending',
    () async {
      final note = a.newNote('v1');
      await a.notes.createNote(note);
      // The edit lands while the server is still processing the batch.
      server.onBeforePush = () =>
          a.notes.saveNote(note.id, title: 'v1b', body: '', now: a.clock.now());

      final report = await a.engine.push.pushOnce();
      expect(report.sent, 1);
      expect(report.applied, 1);
      final saved = (await a.notes.getNote(note.id))!;
      expect(saved.version, 1, reason: 'server version recorded');
      expect(saved.syncStatus, SyncStatus.pending, reason: 'newer edit queued');
      final remaining = await a.outbox();
      expect(remaining, hasLength(1));
      expect(remaining.single.op, SyncOp.update);
      expect(
        remaining.single.baseVersion,
        0,
        reason: 'queued before v1 was known',
      );

      // The follow-up push conflicts on base_version 0 vs server 1; that is
      // the documented outcome for a true race and is surfaced as a conflict.
      server.onBeforePush = null;
      final second = await a.engine.push.pushOnce();
      expect(second.conflicts, 1);
    },
  );

  test(
    'network failure reschedules with growing backoff and parks after ten',
    () async {
      await a.notes.createNote(a.newNote('offline'));
      server.offline = true;
      for (var attempt = 1; attempt <= 10; attempt++) {
        final report = await a.engine.push.pushOnce();
        expect(report.failure, isA<NetworkFailure>());
        final row = (await a.outbox()).single;
        expect(row.attemptCount, attempt);
        if (attempt < 10) {
          expect(row.state, OutboxState.pending);
          expect(row.nextAttemptAt!.isAfter(a.clock.now()), isTrue);
          // Not due yet: nothing is sent until the clock passes the retry time.
          expect((await a.engine.push.pushOnce()).sent, 0);
          a.clock.advance(
            a.engine.push.backoffFor(attempt) + const Duration(seconds: 1),
          );
        } else {
          expect(row.state, OutboxState.failed);
        }
      }
      expect(await a.db.outboxDao.watchFailedCount().first, 1);

      server.offline = false;
      expect(
        (await a.engine.push.pushOnce()).sent,
        0,
        reason: 'failed rows wait for retry',
      );
      final report = await a.engine.retryFailed();
      expect(report.push.applied, 1);
      expect(await a.outbox(), isEmpty);
    },
  );

  test('backoff doubles from 1s and caps at 5 minutes', () {
    final p = a.engine.push;
    expect(p.backoffFor(1), greaterThanOrEqualTo(const Duration(seconds: 1)));
    expect(p.backoffFor(1), lessThan(const Duration(seconds: 2)));
    expect(p.backoffFor(4), greaterThanOrEqualTo(const Duration(seconds: 8)));
    expect(p.backoffFor(20), lessThan(const Duration(minutes: 5, seconds: 1)));
  });

  test('auth failure releases rows without counting an attempt', () async {
    await a.notes.createNote(a.newNote('x'));
    server.sessions.clear(); // server no longer knows the token
    server.adapter.on(
      'POST',
      ApiPaths.syncPush,
      (o) => const FakeResponse401(),
    );
    final report = await a.engine.push.pushOnce();
    expect(report.failure, isA<AuthFailure>());
    final row = (await a.outbox()).single;
    expect(row.state, OutboxState.pending);
    expect(row.attemptCount, 0);
  });

  test('rejected ops are dropped and logged, entity marked synced', () async {
    final note = a.newNote('bad');
    await a.notes.createNote(note);
    // Corrupt the payload so the server cannot parse it.
    final row = (await a.outbox()).single;
    await a.db.outboxDao.remove([row.id]);
    await a.db.outboxDao.enqueue(
      entityType: EntityType.note,
      entityId: note.id,
      op: SyncOp.create,
      payload: const {'title': 'missing body'},
      baseVersion: 0,
      now: a.clock.now(),
    );
    final report = await a.engine.push.pushOnce();
    expect(report.rejected, 1);
    expect(await a.outbox(), isEmpty);
    expect((await a.notes.getNote(note.id))!.syncStatus, SyncStatus.synced);
  });
}
