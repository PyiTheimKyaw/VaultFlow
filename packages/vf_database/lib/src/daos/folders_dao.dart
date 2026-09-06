import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'folders_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FoldersDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$FoldersDaoMixin {
  FoldersDao(super.attachedDatabase);

  Expression<bool> _live($FoldersTable f) => f.deletedAt.isNull();

  SimpleSelectStatement<$FoldersTable, FolderRow> _selectLive() =>
      select(folders)
        ..where(_live)
        ..orderBy([(f) => OrderingTerm.asc(f.name.lower())]);

  Stream<List<FolderRow>> watchAllLive() => _selectLive().watch();

  Future<List<FolderRow>> getAllLive() => _selectLive().get();

  Stream<FolderRow?> watchById(String id) =>
      (select(folders)..where((f) => f.id.equals(id))).watchSingleOrNull();

  Future<FolderRow?> getById(String id) =>
      (select(folders)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<List<FolderRow>> getChildren(String? parentId) =>
      (_selectLive()..where(
            (f) => parentId == null
                ? f.parentId.isNull()
                : f.parentId.equals(parentId),
          ))
          .get();

  Future<void> insertRow(FoldersCompanion row) => into(folders).insert(row);

  Future<void> updateRow(String id, FoldersCompanion changes) =>
      (update(folders)..where((f) => f.id.equals(id))).write(changes);

  /// Upserts a server snapshot (used by the change puller).
  Future<void> upsertRow(FoldersCompanion row) =>
      into(folders).insertOnConflictUpdate(row);

  /// Ids of every live folder below [rootId], depth-first, excluding the
  /// root itself.
  Future<List<FolderRow>> getDescendants(String rootId) async {
    final all = await getAllLive();
    final byParent = <String?, List<FolderRow>>{};
    for (final f in all) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }
    final result = <FolderRow>[];
    final stack = [rootId];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final child in byParent[current] ?? const <FolderRow>[]) {
        result.add(child);
        stack.add(child.id);
      }
    }
    return result;
  }
}
