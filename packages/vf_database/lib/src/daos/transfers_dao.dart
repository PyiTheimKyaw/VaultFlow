import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'transfers_dao.g.dart';

/// Persistence for resumable transfers. The engine that drives these rows
/// arrives with Phase 5; the schema exists now so migrations stay linear.
@DriftAccessor(tables: [TransferSessions, TransferChunks])
class TransfersDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$TransfersDaoMixin {
  TransfersDao(super.attachedDatabase);

  Stream<List<TransferSessionRow>> watchSessions() => (select(
    transferSessions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// One-shot listing, newest first (widget tests cannot await streams).
  Future<List<TransferSessionRow>> listSessions() => (select(
    transferSessions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<TransferSessionRow?> getSession(String id) => (select(
    transferSessions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<TransferSessionRow?> watchSession(String id) => (select(
    transferSessions,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Active or queued session for a document, if any.
  Future<TransferSessionRow?> findActiveFor(String documentId, String kind) =>
      (select(transferSessions)
            ..where(
              (t) =>
                  t.documentId.equals(documentId) &
                  t.kind.equals(kind) &
                  t.state.isIn(['queued', 'running', 'paused', 'failed']),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Oldest queued sessions first.
  Future<List<TransferSessionRow>> nextQueued({int limit = 2}) =>
      (select(transferSessions)
            ..where((t) => t.state.equals('queued'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Sessions left `running` by a crash go back to `queued`.
  Future<int> recoverRunning() =>
      (update(transferSessions)..where((t) => t.state.equals('running'))).write(
        const TransferSessionsCompanion(state: Value('queued')),
      );

  Future<void> setState(
    String id,
    String state, {
    String? error,
    DateTime? now,
  }) => updateSession(
    id,
    TransferSessionsCompanion(
      state: Value(state),
      lastError: Value(error),
      updatedAt: now == null ? const Value.absent() : Value(now),
    ),
  );

  Future<void> setProgress(String id, int bytesDone, DateTime now) =>
      updateSession(
        id,
        TransferSessionsCompanion(
          bytesDone: Value(bytesDone),
          updatedAt: Value(now),
        ),
      );

  Future<void> bumpAttempt(String id, int attemptCount) => updateSession(
    id,
    TransferSessionsCompanion(attemptCount: Value(attemptCount)),
  );

  Future<void> deleteSession(String id) =>
      (delete(transferSessions)..where((t) => t.id.equals(id))).go();

  Future<void> insertSession(TransferSessionsCompanion row) =>
      into(transferSessions).insert(row);

  Future<void> updateSession(String id, TransferSessionsCompanion changes) =>
      (update(transferSessions)..where((t) => t.id.equals(id))).write(changes);

  Future<List<TransferChunkRow>> getChunks(String sessionId) =>
      (select(transferChunks)
            ..where((c) => c.sessionId.equals(sessionId))
            ..orderBy([(c) => OrderingTerm.asc(c.idx)]))
          .get();

  Future<void> insertChunks(Iterable<TransferChunksCompanion> rows) =>
      batch((b) => b.insertAll(transferChunks, rows));

  Future<void> updateChunk(
    String sessionId,
    int idx,
    TransferChunksCompanion changes,
  ) =>
      (update(transferChunks)
            ..where((c) => c.sessionId.equals(sessionId) & c.idx.equals(idx)))
          .write(changes);

  Future<void> markChunkDone(String sessionId, int idx, {String? etag}) =>
      updateChunk(
        sessionId,
        idx,
        TransferChunksCompanion(state: const Value('done'), etag: Value(etag)),
      );

  Future<void> resetChunks(String sessionId) =>
      (update(transferChunks)..where((c) => c.sessionId.equals(sessionId)))
          .write(const TransferChunksCompanion(state: Value('pending')));
}
