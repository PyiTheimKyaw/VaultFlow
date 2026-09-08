import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/background_sync.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/auth/application/device_info.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_sync/vf_sync.dart';

part 'sync_coordinator.g.dart';

const _log = Logger('sync_coordinator');

/// Whether the scheduler runs. Tests turn it off so widget tests do not
/// hit the network; the engine itself stays available for resolving.
@Riverpod(keepAlive: true)
bool syncEnabled(Ref ref) => true;

/// Owns the engine and scheduler for the signed-in session: created on
/// sign-in, torn down on sign-out, kicked on app resume.
@Riverpod(keepAlive: true)
class SyncCoordinator extends _$SyncCoordinator {
  SyncEngine? _engine;
  SyncScheduler? _scheduler;
  AppLifecycleListener? _lifecycle;

  @override
  SyncEngine? build() {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      // Only identity changes matter. The session object is also replaced
      // when the profile email arrives after sign-in; rebuilding then would
      // dispose an engine mid-round.
      if (!_sameIdentity(previous, next)) _rebuild(next);
    });
    ref.onDispose(_teardown);
    return _create(ref.read(sessionControllerProvider));
  }

  static bool _sameIdentity(SessionState? a, SessionState b) =>
      switch ((a, b)) {
        (
          SignedIn(userId: final u1, deviceId: final d1),
          SignedIn(userId: final u2, deviceId: final d2),
        ) =>
          u1 == u2 && d1 == d2,
        (SignedOut(), SignedOut()) => true,
        _ => false,
      };

  void _rebuild(SessionState session) {
    _teardown();
    if (session is! SignedIn) unawaited(cancelBackgroundSync());
    state = _create(session);
  }

  SyncEngine? _create(SessionState session) {
    if (session is! SignedIn) return null;
    final engine = _engine = SyncEngine(
      db: ref.read(databaseProvider),
      api: ref.read(apiClientProvider),
      deviceId: session.deviceId,
      deviceLabel: DeviceInfo.name,
    );
    unawaited(_start(engine));
    return engine;
  }

  Future<void> _start(SyncEngine engine) async {
    await engine.recover();
    if (!ref.read(syncEnabledProvider)) return;
    final scheduler = SyncScheduler(
      engine: engine,
      connectivity: ref.read(connectivityProvider),
      outboxCount: ref.read(outboxRepositoryProvider).watchPendingCount(),
    );
    _scheduler = scheduler;
    _lifecycle = AppLifecycleListener(onResume: scheduler.onAppResumed);
    scheduler.start();
    _log.info('sync scheduler started');
    await registerBackgroundSync();
  }

  // Reads a private field rather than `state`: Riverpod forbids touching
  // `state` inside dispose callbacks.
  void _teardown() {
    _scheduler?.stop();
    _scheduler = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _engine?.dispose();
    _engine = null;
  }

  /// User-initiated sync; no-op when signed out.
  Future<SyncReport?> syncNow() => state?.syncNow() ?? Future.value();

  Future<SyncReport?> retryFailed() => state?.retryFailed() ?? Future.value();

  Future<Result<void>> resolve(String conflictId, ConflictResolution choice) {
    final engine = state;
    if (engine == null) {
      return Future.value(const Err(AuthFailure('Not signed in')));
    }
    return engine.resolveConflict(conflictId, choice);
  }
}

/// Live engine state (phase, last sync, last error) as a stream.
@riverpod
Stream<SyncEngineState> syncState(Ref ref) {
  final engine = ref.watch(syncCoordinatorProvider);
  if (engine == null) return Stream.value(const SyncEngineState());
  final controller = StreamController<SyncEngineState>();
  void push() => controller.add(engine.state.value);
  engine.state.addListener(push);
  push();
  ref.onDispose(() {
    engine.state.removeListener(push);
    unawaited(controller.close());
  });
  return controller.stream;
}

@riverpod
Stream<List<Conflict>> conflicts(Ref ref) {
  final engine = ref.watch(syncCoordinatorProvider);
  if (engine == null) return Stream.value(const []);
  return engine.watchConflicts();
}

@riverpod
Stream<int> failedOutboxCount(Ref ref) =>
    ref.watch(databaseProvider).outboxDao.watchFailedCount();
