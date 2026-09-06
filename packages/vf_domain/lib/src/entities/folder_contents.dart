import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_domain/src/entities/document.dart';
import 'package:vf_domain/src/entities/folder.dart';
import 'package:vf_domain/src/entities/note.dart';

part 'folder_contents.freezed.dart';

/// Live (non-deleted) children of one folder, each list sorted by name.
@freezed
abstract class FolderContents with _$FolderContents {
  const factory FolderContents({
    required String? folderId,
    @Default(<Folder>[]) List<Folder> folders,
    @Default(<Document>[]) List<Document> documents,
    @Default(<Note>[]) List<Note> notes,
  }) = _FolderContents;

  const FolderContents._();

  bool get isEmpty => folders.isEmpty && documents.isEmpty && notes.isEmpty;
  int get length => folders.length + documents.length + notes.length;
}
