import 'dart:math';

import 'package:meta/meta.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';

const _log = Logger('outbox');

/// Outcome of one push round.
@immutable
class PushReport {
  const PushReport({
    this.sent = 0,
    this.applied = 0,
    this.conflicts = 0,
    this.rejected = 0,
    this.failure,
  });

  final int sent;
  final int applied;
  final int conflicts;
  final int rejected;

  /// Set when the batch could not be delivered (network, auth, server).
  final Failure? failure;

  bool get isOk => failure == null;
}

/// Drains the outbox in FIFO batches.
///
/// * `applied` → entity gets the server version and becomes `synced`
///   (unless a newer outbox row exists for it).
/// * `conflict` → a `conflicts` row is written with both snapshots, the
///   entity is flagged `conflicted`, and the op is dropped.
/// * `rejected` → logged and dropped; the entity is marked `synced` so it
///   stops being retried (the server is authoritative).
/// * delivery failure → every row in the batch is rescheduled with
///   exponential backoff (1 s doubling to 5 min, with jitter) and parked as
///   `failed` after [maxAttempts].
class OutboxProcessor {
  OutboxProcessor({
    required VaultFlowDatabase db,
    required this.api,
    required this.deviceId,
    this.clock = const SystemClock(),
    Random? random,
    this.batchSize = vfMaxPushOps,
    this.maxAttempts = 10,
    this.minBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(minutes: 5),
  }) : _db = db,
       _repo = DriftSyncRepository(db),
       _random = random ?? Random();

  final VaultFlowDatabase _db;
  final DriftSyncRepository _repo;
  final ApiClient api;
  final String deviceId;
  final Clock clock;
  final Random _random;
  final int batchSize;
  final int maxAttempts;
  final Duration minBackoff;
  final Duration maxBackoff;

  OutboxDao get _outbox => _db.outboxDao;

  /// Sends one batch. Returns `sent == 0` when nothing was due.
  Future<PushReport> pushOnce() async {
    final now = clock.now();
    final rows = await _outbox.nextPending(limit: batchSize, now: now);
    if (rows.isEmpty) return const PushReport();
    final ids = rows.map((r) => r.id).toList();
    await _outbox.markInFlight(ids);

    final request = PushRequest(
      deviceId: deviceId,
      ops: rows.map((r) => Mappers.outbox(r).toRequest()).toList(),
    );
    final result = await api.push(request);

    switch (result) {
      case Err(:final failure):
        await _handleDeliveryFailure(rows, failure, now);
        return PushReport(sent: rows.length, failure: failure);
      case Ok(:final value):
        return await _applyResults(rows, value, now);
    }
  }

  Future<void> _handleDeliveryFailure(
    List<OutboxRow> rows,
    Failure failure,
    DateTime now,
  ) async {
    if (failure is AuthFailure) {
      // Not the rows' fault: retry as soon as the session is back.
      await _outbox.release(rows.map((r) => r.id));
      _log.warning('push rejected: session lost');
      return;
    }
    for (final row in rows) {
      final attempt = row.attemptCount + 1;
      final giveUp = attempt >= maxAttempts;
      await _outbox.scheduleRetry(
        row.id,
        attemptCount: attempt,
        nextAttemptAt: now.add(backoffFor(attempt)),
        error: failure.message,
        giveUp: giveUp,
      );
      if (giveUp) {
        _log.error(
          'outbox op parked as failed',
          fields: {'op': row.clientOpId, 'entity': row.entityId},
        );
      }
    }
    _log.debug(
      'push failed; batch rescheduled',
      fields: {'rows': rows.length, 'error': failure.message},
    );
  }

  /// `min(minBackoff * 2^(attempt-1), maxBackoff)` plus up to one second of
  /// jitter so many devices do not retry in lockstep.
  @visibleForTesting
  Duration backoffFor(int attempt) {
    final exp = attempt <= 1 ? 1 : 1 << min(attempt - 1, 20);
    var base = minBackoff * exp;
    if (base > maxBackoff) base = maxBackoff;
    return base + Duration(milliseconds: _random.nextInt(1000));
  }

  Future<PushReport> _applyResults(
    List<OutboxRow> rows,
    PushResponse response,
    DateTime now,
  ) async {
    final byOpId = {for (final r in response.results) r.clientOpId: r};
    var applied = 0;
    var conflicts = 0;
    var rejected = 0;
    final done = <int>[];
    final orphaned = <int>[];

    for (final row in rows) {
      final result = byOpId[row.clientOpId];
      if (result == null) {
        orphaned.add(row.id);
        continue;
      }
      _log.info(
        'push result',
        fields: {
          'op': row.op.name,
          'entity': row.entityId,
          'status': result.status.name,
          'newVersion': result.newVersion,
          'remoteVersion': result.remoteVersion,
        },
      );
      switch (result.status) {
        case SyncOpStatus.applied:
          await _repo.markApplied(
            row.entityType,
            row.entityId,
            version: result.newVersion ?? row.baseVersion + 1,
          );
          applied++;
        case SyncOpStatus.conflict:
          await _recordConflict(row, result, now);
          conflicts++;
        case SyncOpStatus.rejected:
          _log.warning(
            'op rejected by server',
            fields: {
              'op': row.clientOpId,
              'entity': row.entityId,
              'reason': result.error,
            },
          );
          await _repo.markSynced(row.entityType, row.entityId);
          rejected++;
      }
      done.add(row.id);
    }
    await _outbox.remove(done);
    if (orphaned.isNotEmpty) await _outbox.release(orphaned);
    _log.info(
      'push batch done',
      fields: {
        'applied': applied,
        'conflicts': conflicts,
        'rejected': rejected,
        'orphaned': orphaned.length,
      },
    );
    return PushReport(
      sent: rows.length,
      applied: applied,
      conflicts: conflicts,
      rejected: rejected,
    );
  }

  Future<void> _recordConflict(
    OutboxRow row,
    SyncOpResult result,
    DateTime now,
  ) async {
    final local = switch (row.op) {
      SyncOp.create || SyncOp.update => row.payload,
      _ =>
        await _repo.localSnapshot(row.entityType, row.entityId) ?? row.payload,
    };
    final existing = await _db.conflictsDao.findUnresolvedFor(
      row.entityType,
      row.entityId,
    );
    if (existing == null) {
      await _repo.recordConflict(
        id: VfId.next(),
        type: row.entityType,
        entityId: row.entityId,
        local: local,
        remote: result.remote ?? const {},
        remoteVersion: result.remoteVersion ?? 0,
        now: now,
      );
    }
    await _repo.markConflicted(row.entityType, row.entityId);
    _log.info(
      'conflict recorded',
      fields: {'entity': row.entityId, 'new': existing == null},
    );
  }
}
