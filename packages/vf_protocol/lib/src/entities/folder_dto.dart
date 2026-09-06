import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_dto.freezed.dart';
part 'folder_dto.g.dart';

/// Server representation of a folder.
@freezed
abstract class FolderDto with _$FolderDto {
  const factory FolderDto({
    required String id,
    required String name,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentId,
    DateTime? deletedAt,
  }) = _FolderDto;

  factory FolderDto.fromJson(Map<String, Object?> json) =>
      _$FolderDtoFromJson(json);
}
