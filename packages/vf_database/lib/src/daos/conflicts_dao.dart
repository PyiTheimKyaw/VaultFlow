import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'conflicts_dao.g.dart';

@DriftAccessor(tables: [Conflicts])
class ConflictsDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$ConflictsDaoMixin {
  ConflictsDao(super.attachedDatabase);

  Stream<List<ConflictRow>> watchUnresolved() =>
      (select(conflicts)
            ..where((c) => c.resolvedAt.isNull())
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  Future<ConflictRow?> getById(String id) =>
      (select(conflicts)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(ConflictsCompanion row) => into(conflicts).insert(row);

  Future<void> updateRow(String id, ConflictsCompanion changes) =>
      (update(conflicts)..where((c) => c.id.equals(id))).write(changes);
}
