import 'package:drift/drift.dart';
import 'package:vf_database/src/database.dart';

part 'documents_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentsDao extends DatabaseAccessor<VaultFlowDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.attachedDatabase);

  SimpleSelectStatement<$DocumentsTable, DocumentRow> _selectLive() =>
      select(documents)
        ..where((d) => d.deletedAt.isNull())
        ..orderBy([(d) => OrderingTerm.asc(d.name.lower())]);

  Future<List<DocumentRow>> getIn(String? folderId) =>
      (_selectLive()..where(
            (d) => folderId == null
                ? d.folderId.isNull()
                : d.folderId.equals(folderId),
          ))
          .get();

  /// Live documents anywhere under the given folder ids.
  Future<List<DocumentRow>> getInAny(Iterable<String?> folderIds) {
    final ids = folderIds.whereType<String>().toList();
    final includeRoot = folderIds.contains(null);
    return (_selectLive()..where(
          (d) => includeRoot
              ? d.folderId.isNull() | d.folderId.isIn(ids)
              : d.folderId.isIn(ids),
        ))
        .get();
  }

  Stream<DocumentRow?> watchById(String id) =>
      (select(documents)..where((d) => d.id.equals(id))).watchSingleOrNull();

  Future<DocumentRow?> getById(String id) =>
      (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(DocumentsCompanion row) => into(documents).insert(row);

  Future<void> updateRow(String id, DocumentsCompanion changes) =>
      (update(documents)..where((d) => d.id.equals(id))).write(changes);

  Future<void> upsertRow(DocumentsCompanion row) =>
      into(documents).insertOnConflictUpdate(row);
}
