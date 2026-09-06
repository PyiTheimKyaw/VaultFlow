import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_dto.freezed.dart';
part 'document_dto.g.dart';

/// Server representation of a document (binary file).
@freezed
abstract class DocumentDto with _$DocumentDto {
  const factory DocumentDto({
    required String id,
    required String name,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Parent folder; `null` for the vault root.
    String? folderId,

    /// Object-storage key; `null` until the upload session completes.
    String? storageKey,
    DateTime? deletedAt,
  }) = _DocumentDto;

  factory DocumentDto.fromJson(Map<String, Object?> json) =>
      _$DocumentDtoFromJson(json);
}
