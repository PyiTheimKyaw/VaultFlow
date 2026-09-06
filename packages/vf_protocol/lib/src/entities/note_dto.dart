import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_dto.freezed.dart';
part 'note_dto.g.dart';

/// Server representation of a Markdown note.
@freezed
abstract class NoteDto with _$NoteDto {
  const factory NoteDto({
    required String id,
    required String title,
    required String body,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Parent folder; `null` for the vault root.
    String? folderId,
    DateTime? deletedAt,
  }) = _NoteDto;

  factory NoteDto.fromJson(Map<String, Object?> json) =>
      _$NoteDtoFromJson(json);
}
