import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_domain/src/entities/sync_status.dart';

part 'note.freezed.dart';

/// A Markdown note stored inline in the database.
@freezed
abstract class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? folderId,
    @Default(0) int version,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Note;

  const Note._();

  bool get isDeleted => deletedAt != null;

  /// First non-empty line of the body, for list previews.
  String get preview {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
