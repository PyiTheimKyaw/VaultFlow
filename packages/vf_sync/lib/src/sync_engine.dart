import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_sync/src/change_puller.dart';
import 'package:vf_sync/src/conflict_resolver.dart';
import 'package:vf_sync/src/outbox_processor.dart';

const _log = Logger('sync');

enum SyncPhase { idle, pushing, pulling }

/// What the UI shows about the engine.
@immutable
class SyncEngineState {
  const SyncEngineState({
    this.phase = SyncPhase.idle,
    this.lastSyncAt,
    this.lastError,
    this.offline = false,
  });

  final SyncPhase phase;
  final DateTime? lastSyncAt;
  final Failure? lastError;

  /// The last round failed with a network error.
  final bool offline;

  bool get isSyncing => phase != SyncPhase.idle;

  SyncEngineState copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    Failure? lastError,
    bool clearError = false,
    bool? offline,
  }) => SyncEngineState(
    phase: phase ?? this.phase,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
    offline: offline ?? this.offline,
  );
}

/// Result of one `syncNow` round.
@immutable
class SyncReport {
  const SyncReport({required this.push, required this.pull});

  final PushReport push;
  final PullReport pull;

  Failure? get failure => push.failure ?? pull.failure;
  bool get isOk => failure == null;
}

/// Push then pull, single-flight. Owns the processor, puller and resolver.
class SyncEngine {
  SyncEngine({
    required this.db,
    required ApiClient api,
    required this.deviceId,
    required String deviceLabel,
    Clock clock = const SystemClock(),
    Random? random,
    this.maxPushRounds = 20,
  }) : _clock = clock,
       push = OutboxProcessor(
         db: db,
         api: api,
         deviceId: deviceId,
         clock: clock,
         random: random,
       ),
       pull = ChangePuller(db: db, api: api, deviceId: deviceId),
       resolver = ConflictResolver(
         db: db,
         deviceLabel: deviceLabel,
         clock: clock,
       );

  final VaultFlowDatabase db;
  final String deviceId;
  final OutboxProcessor push;
  final ChangePuller pull;
  final ConflictResolver resolver;
  final Clock _clock;

  /// Upper bound on batches per round; the next round picks up the rest.
  final int maxPushRounds;

  final ValueNotifier<SyncEngineState> state = ValueNotifier(
    const SyncEngineState(),
  );
  Future<SyncReport>? _inFlight;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// State writes after [dispose] are dropped: a round that was already
  /// running when the session ended must not touch a dead notifier.
  void _setState(SyncEngineState next) {
    if (_disposed) return;
    state.value = next;
  }

  /// Call once at start-up: rows left in flight by a crash become pending.
  Future<void> recover() async {
    final released = await db.outboxDao.recoverInFlight();
    if (released > 0) {
      _log.info('recovered in-flight outbox rows', fields: {'rows': released});
    }
    final lastSync = await db.settingsDao.getSyncState(
      SettingsDao.lastSyncAtKey,
    );
    if (lastSync != null) {
      _setState(state.value.copyWith(lastSyncAt: DateTime.tryParse(lastSync)));
    }
  }

  /// Runs a full round. Concurrent callers share the running round.
  Future<SyncReport> syncNow() {
    final running = _inFlight;
    if (running != null) return running;
    final future = _run().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<SyncReport> _run() async {
    _setState(state.value.copyWith(phase: SyncPhase.pushing, clearError: true));
    var pushReport = const PushReport();
    for (var round = 0; round < maxPushRounds; round++) {
      final report = await push.pushOnce();
      pushReport = PushReport(
        sent: pushReport.sent + report.sent,
        applied: pushReport.applied + report.applied,
        conflicts: pushReport.conflicts + report.conflicts,
        rejected: pushReport.rejected + report.rejected,
        failure: report.failure,
      );
      if (report.sent == 0 || !report.isOk) break;
    }

    PullReport pullReport;
    if (pushReport.isOk) {
      _setState(state.value.copyWith(phase: SyncPhase.pulling));
      pullReport = await pull.pullOnce();
    } else {
      pullReport = const PullReport();
    }

    final report = SyncReport(push: pushReport, pull: pullReport);
    final failure = report.failure;
    if (failure == null) {
      final now = _clock.now();
      await db.settingsDao.setSyncState(
        SettingsDao.lastSyncAtKey,
        now.toIso8601String(),
      );
      _setState(SyncEngineState(lastSyncAt: now));
    } else {
      _log.warning('sync round failed', error: failure);
      _setState(
        state.value.copyWith(
          phase: SyncPhase.idle,
          lastError: failure,
          offline: failure is NetworkFailure,
        ),
      );
    }
    return report;
  }

  Stream<List<Conflict>> watchConflicts() =>
      DriftSyncRepository(db).watchConflicts();

  Future<Result<void>> resolveConflict(String id, ConflictResolution choice) =>
      resolver.resolve(id, choice);

  /// Puts every failed op back in the queue and syncs.
  Future<SyncReport> retryFailed() async {
    await db.outboxDao.retryFailed();
    return await syncNow();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    state.dispose();
  }
}
