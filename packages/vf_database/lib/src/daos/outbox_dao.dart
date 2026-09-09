import 'package:drift/drift.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_domain/vf_domain.dart';

part 'outbox_dao.g.dart';

/// The sync queue. [enqueue] applies the coalescing rules from the
/// architecture doc so an entity edited many times offline pushes once.
@DriftAccessor(tables: [SyncOutbox])
class OutboxDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$OutboxDaoMixin {
  OutboxDao(super.attachedDatabase);

  static const List<OutboxState> _mergeable = [
    OutboxState.pending,
    OutboxState.blocked,
  ];

  Stream<List<OutboxRow>> watchAll() =>
      (select(syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.id)])).watch();

  Stream<int> watchCount() {
    final count = countAll();
    return (selectOnly(
      syncOutbox,
    )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<OutboxRow>> getAll() =>
      (select(syncOutbox)..orderBy([(o) => OrderingTerm.asc(o.id)])).get();

  Future<OutboxRow?> _findMergeable(EntityType type, String entityId) =>
      (select(syncOutbox)
            ..where(
              (o) =>
                  o.entityType.equalsValue(type) &
                  o.entityId.equals(entityId) &
                  o.state.isInValues(_mergeable),
            )
            ..orderBy([(o) => OrderingTerm.desc(o.id)])
            ..limit(1))
          .getSingleOrNull();

  /// Queues [op] for an entity, merging with a still-pending row when the
  /// rules allow it. Must be called inside the same transaction as the
  /// entity write.
  ///
  /// Rules (existing + new → result):
  /// * create + update/move → create with merged payload
  /// * update + update/move → update with merged payload
  /// * move + move → move with the newer payload
  /// * create + delete → both dropped (the server never saw the entity)
  /// * update/move + delete → delete
  /// * in-flight rows are never touched; a new row is appended instead.
  Future<void> enqueue({
    required EntityType entityType,
    required String entityId,
    required SyncOp op,
    required Map<String, Object?> payload,
    required int baseVersion,
    required DateTime now,
    String? dependsOnTransfer,
  }) async {
    final existing = await _findMergeable(entityType, entityId);
    if (existing == null) {
      await into(syncOutbox).insert(
        SyncOutboxCompanion.insert(
          clientOpId: VfId.random(),
          entityType: entityType,
          entityId: entityId,
          op: op,
          payload: payload,
          baseVersion: baseVersion,
          createdAt: now,
          state: Value(
            dependsOnTransfer == null
                ? OutboxState.pending
                : OutboxState.blocked,
          ),
          dependsOnTransfer: Value(dependsOnTransfer),
        ),
      );
      return;
    }

    final merged = <String, Object?>{...existing.payload, ...payload};
    switch ((existing.op, op)) {
      case (SyncOp.create, SyncOp.update) || (SyncOp.create, SyncOp.move):
        await _rewrite(existing.id, op: SyncOp.create, payload: merged);
      case (SyncOp.update, SyncOp.update) || (SyncOp.update, SyncOp.move):
        await _rewrite(existing.id, op: SyncOp.update, payload: merged);
      case (SyncOp.move, SyncOp.update):
        await _rewrite(existing.id, op: SyncOp.update, payload: merged);
      case (SyncOp.move, SyncOp.move):
        await _rewrite(existing.id, op: SyncOp.move, payload: payload);
      case (SyncOp.create, SyncOp.delete):
        await (delete(syncOutbox)..where((o) => o.id.equals(existing.id))).go();
      case (SyncOp.update, SyncOp.delete) || (SyncOp.move, SyncOp.delete):
        await _rewrite(existing.id, op: SyncOp.delete, payload: const {});
      case (_, SyncOp.create) || (SyncOp.delete, _):
        // Re-creating a deleted entity or mutating after delete: queue as-is
        // so the server sees the exact sequence.
        await into(syncOutbox).insert(
          SyncOutboxCompanion.insert(
            clientOpId: VfId.random(),
            entityType: entityType,
            entityId: entityId,
            op: op,
            payload: payload,
            baseVersion: baseVersion,
            createdAt: now,
          ),
        );
    }
  }

  Future<void> _rewrite(
    int id, {
    required SyncOp op,
    required Map<String, Object?> payload,
  }) => (update(syncOutbox)..where((o) => o.id.equals(id))).write(
    SyncOutboxCompanion(op: Value(op), payload: Value(payload)),
  );

  /// Next batch of pushable rows, oldest first.
  Future<List<OutboxRow>> nextPending({int limit = 100, DateTime? now}) =>
      (select(syncOutbox)
            ..where(
              (o) =>
                  o.state.equalsValue(OutboxState.pending) &
                  (o.nextAttemptAt.isNull() |
                      o.nextAttemptAt.isSmallerOrEqualValue(
                        now ?? DateTime.now().toUtc(),
                      )),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.id)])
            ..limit(limit))
          .get();

  Future<void> markInFlight(Iterable<int> ids) =>
      (update(syncOutbox)..where((o) => o.id.isIn(ids))).write(
        const SyncOutboxCompanion(state: Value(OutboxState.inFlight)),
      );

  Future<void> remove(Iterable<int> ids) =>
      (delete(syncOutbox)..where((o) => o.id.isIn(ids))).go();

  /// Records a failed attempt. The row goes back to `pending` with a retry
  /// time, or to `failed` once [giveUp] is set (surfaced in the UI, never
  /// dropped).
  Future<void> scheduleRetry(
    int id, {
    required int attemptCount,
    required DateTime nextAttemptAt,
    required String error,
    required bool giveUp,
  }) => (update(syncOutbox)..where((o) => o.id.equals(id))).write(
    SyncOutboxCompanion(
      state: Value(giveUp ? OutboxState.failed : OutboxState.pending),
      lastError: Value(error),
      nextAttemptAt: Value(nextAttemptAt),
      attemptCount: Value(attemptCount),
    ),
  );

  /// Puts rows back to `pending` without counting an attempt (e.g. the
  /// request never left the device, or the process restarted mid-push).
  Future<void> release(Iterable<int> ids) =>
      (update(syncOutbox)..where((o) => o.id.isIn(ids))).write(
        const SyncOutboxCompanion(state: Value(OutboxState.pending)),
      );

  /// Rows left `in_flight` by a crash; call once at start-up.
  Future<int> recoverInFlight() =>
      (update(syncOutbox)
            ..where((o) => o.state.equalsValue(OutboxState.inFlight)))
          .write(const SyncOutboxCompanion(state: Value(OutboxState.pending)));

  /// Retries every `failed` row immediately ("Retry" in the UI).
  Future<int> retryFailed() =>
      (update(
        syncOutbox,
      )..where((o) => o.state.equalsValue(OutboxState.failed))).write(
        const SyncOutboxCompanion(
          state: Value(OutboxState.pending),
          attemptCount: Value(0),
          nextAttemptAt: Value(null),
        ),
      );

  Stream<int> watchFailedCount() {
    final count = countAll();
    return (selectOnly(syncOutbox)
          ..addColumns([count])
          ..where(syncOutbox.state.equalsValue(OutboxState.failed)))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Merges [patch] into the payload of rows blocked on [transferId] (the
  /// document create learns its `storage_key` when the upload completes).
  Future<void> patchBlockedPayload(
    String transferId,
    Map<String, Object?> patch,
  ) async {
    final rows = await (select(
      syncOutbox,
    )..where((o) => o.dependsOnTransfer.equals(transferId))).get();
    for (final row in rows) {
      await (update(syncOutbox)..where((o) => o.id.equals(row.id))).write(
        SyncOutboxCompanion(payload: Value({...row.payload, ...patch})),
      );
    }
  }

  /// Releases rows waiting on a completed transfer.
  Future<void> unblock(String transferId) =>
      (update(
        syncOutbox,
      )..where((o) => o.dependsOnTransfer.equals(transferId))).write(
        const SyncOutboxCompanion(
          state: Value(OutboxState.pending),
          dependsOnTransfer: Value(null),
        ),
      );

  /// Whether the entity has a coalescable (pending/blocked) row.
  Future<bool> hasPending(EntityType type, String entityId) async =>
      await _findMergeable(type, entityId) != null;

  /// Whether any local edit for the entity has not reached the server,
  /// including rows in flight or parked as failed.
  Future<bool> hasUnsynced(EntityType type, String entityId) async {
    final row =
        await (select(syncOutbox)
              ..where(
                (o) =>
                    o.entityType.equalsValue(type) &
                    o.entityId.equals(entityId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}
