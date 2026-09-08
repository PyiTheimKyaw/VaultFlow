import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_sync/vf_sync.dart';

import 'helpers.dart';

void main() {
  late FakeSyncServer server;
  late Device a;

  setUp(() async {
    server = FakeSyncServer();
    a = await Device.create(server, name: 'A');
  });

  tearDown(() => a.close());

  test('concurrent syncNow calls share one round', () async {
    await a.notes.createNote(a.newNote('x'));
    final r1 = a.engine.syncNow();
    final r2 = a.engine.syncNow();
    expect(identical(r1, r2), isTrue);
    await r1;
    expect(server.pushes, 1);
    expect(a.engine.state.value.lastSyncAt, isNotNull);
    expect(a.engine.state.value.phase, SyncPhase.idle);
  });

  test(
    'state reports offline after a network failure and clears on success',
    () async {
      await a.notes.createNote(a.newNote('x'));
      server.offline = true;
      final failed = await a.engine.syncNow();
      expect(failed.isOk, isFalse);
      expect(a.engine.state.value.offline, isTrue);
      expect(a.engine.state.value.lastError, isA<NetworkFailure>());
      server.offline = false;
      a.clock.advance(const Duration(seconds: 5));
      final ok = await a.engine.syncNow();
      expect(ok.isOk, isTrue);
      expect(a.engine.state.value.offline, isFalse);
      expect(a.engine.state.value.lastError, isNull);
    },
  );

  test('scheduler syncs on start, connectivity, mutation (debounced), resume and period', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivityMonitor(initiallyOnline: false);
      var rounds = 0;
      final engine = _CountingEngine(a, () => rounds++);
      final outbox = StreamControllerFixture();
      final scheduler = SyncScheduler(
        engine: engine,
        connectivity: connectivity,
        outboxCount: outbox.stream,
      )..start();
      async.flushMicrotasks();
      expect(rounds, 1, reason: 'start');

      connectivity.online = true;
      async.flushMicrotasks();
      expect(rounds, 2, reason: 'connectivity regained');

      scheduler.onAppResumed();
      async.flushMicrotasks();
      expect(rounds, 3, reason: 'resume');

      async.elapse(const Duration(minutes: 15));
      expect(rounds, 4, reason: 'periodic');

      scheduler.stop();
      async.elapse(const Duration(minutes: 30));
      expect(rounds, 4, reason: 'stopped');
    });
  });

  test('scheduler debounces bursts of local mutations', () {
    fakeAsync((async) {
      final connectivity = FakeConnectivityMonitor();
      var rounds = 0;
      final engine = _CountingEngine(a, () => rounds++);
      final counts = StreamControllerFixture();
      final scheduler = SyncScheduler(
        engine: engine,
        connectivity: connectivity,
        outboxCount: counts.stream,
      )..start();
      async.flushMicrotasks();
      expect(rounds, 1);
      counts
        ..add(1)
        ..add(2)
        ..add(3);
      async.elapse(const Duration(seconds: 1));
      expect(rounds, 1, reason: 'still debouncing');
      async.elapse(const Duration(seconds: 2));
      expect(rounds, 2, reason: 'one sync for the burst');
      counts.add(0);
      async.elapse(const Duration(seconds: 3));
      expect(rounds, 2, reason: 'draining to zero is not a mutation');
      scheduler.stop();
    });
  });

  test(
    'a round that outlives dispose finishes without touching state',
    () async {
      await a.notes.createNote(a.newNote('late'));
      final gate = Completer<void>();
      server.onBeforePush = () => gate.future;
      final round = a.engine.syncNow();
      await Future<void>.delayed(Duration.zero);
      a.engine.dispose();
      expect(a.engine.isDisposed, isTrue);
      gate.complete();
      final report = await round;
      expect(report.push.applied, 1, reason: 'the push itself still completes');
      // Disposing twice is harmless.
      a.engine.dispose();
    },
  );
}

/// Engine whose rounds are counted instead of run (scheduler tests).
class _CountingEngine extends SyncEngine {
  _CountingEngine(Device device, this.onRound)
    : super(
        db: device.db,
        api: device.engine.push.api,
        deviceId: device.engine.deviceId,
        deviceLabel: 'counting',
      );

  final void Function() onRound;

  @override
  Future<SyncReport> syncNow() {
    onRound();
    return Future.value(
      const SyncReport(push: PushReport(), pull: PullReport()),
    );
  }
}
