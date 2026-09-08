import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';
import 'package:vf_domain/vf_domain.dart';

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

  Future<List<ConflictRow>> getUnresolved() =>
      (select(conflicts)..where((c) => c.resolvedAt.isNull())).get();

  Future<ConflictRow?> findUnresolvedFor(EntityType type, String entityId) =>
      (select(conflicts)
            ..where(
              (c) =>
                  c.entityType.equalsValue(type) &
                  c.entityId.equals(entityId) &
                  c.resolvedAt.isNull(),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<void> resolve(String id, ConflictResolution resolution, DateTime at) =>
      updateRow(
        id,
        ConflictsCompanion(
          resolvedAt: Value(at),
          resolution: Value(resolution),
        ),
      );

  Stream<int> watchUnresolvedCount() {
    final count = countAll();
    return (selectOnly(conflicts)
          ..addColumns([count])
          ..where(conflicts.resolvedAt.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }
}
