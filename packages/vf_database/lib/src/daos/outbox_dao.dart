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

  Future<void> markFailed(
    int id, {
    required String error,
    required DateTime nextAttemptAt,
    required bool giveUp,
  }) => (update(syncOutbox)..where((o) => o.id.equals(id))).write(
    SyncOutboxCompanion(
      state: Value(giveUp ? OutboxState.failed : OutboxState.pending),
      lastError: Value(error),
      nextAttemptAt: Value(nextAttemptAt),
      attemptCount: const Value(0),
    ),
  );

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

  /// Whether the entity has a row that has not reached the server yet.
  Future<bool> hasPending(EntityType type, String entityId) async =>
      await _findMergeable(type, entityId) != null;
}
