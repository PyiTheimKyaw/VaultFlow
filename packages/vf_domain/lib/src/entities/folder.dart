import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_domain/src/entities/sync_status.dart';

part 'folder.freezed.dart';

/// A folder in the vault tree. `parentId == null` means the root.
@freezed
abstract class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentId,
    @Default(0) int version,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Folder;

  const Folder._();

  bool get isDeleted => deletedAt != null;
  bool get isRoot => parentId == null;
}
