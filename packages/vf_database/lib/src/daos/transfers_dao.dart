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

  Future<TransferSessionRow?> getSession(String id) => (select(
    transferSessions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

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
}
