import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/src/entities/note.dart';
import 'package:vf_domain/src/repositories/notes_repository.dart';
import 'package:vf_domain/src/repositories/vault_repository.dart';

/// Note-specific use cases. Titles may be empty (an untitled note); bodies
/// are free text with no size limit beyond SQLite's.
final class NotesUseCases {
  const NotesUseCases({
    required this.notes,
    required this.vault,
    this.clock = const SystemClock(),
    this.newId = VfId.next,
  });

  final NotesRepository notes;
  final VaultRepository vault;
  final Clock clock;
  final String Function() newId;

  static const int maxTitleLength = 255;

  Future<Result<Note>> create({String? folderId, String title = ''}) async {
    if (folderId != null && await vault.getFolder(folderId) == null) {
      return const Err(NotFoundFailure('Folder not found'));
    }
    final now = clock.now();
    final note = Note(
      id: newId(),
      title: title.trim(),
      body: '',
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
    );
    return await Result.guard(() async {
      await notes.createNote(note);
      return note;
    }, onError: _storage);
  }

  /// Persists an edit. No-op (still `Ok`) when nothing changed, so editors can
  /// call it freely from an autosave timer.
  Future<Result<void>> save({
    required String id,
    required String title,
    required String body,
  }) async {
    if (title.length > maxTitleLength) {
      return const Err(ValidationFailure('Title is too long', field: 'title'));
    }
    final existing = await notes.getNote(id);
    if (existing == null || existing.isDeleted) {
      return const Err(NotFoundFailure('Note not found'));
    }
    final trimmedTitle = title.trim();
    if (existing.title == trimmedTitle && existing.body == body) return okVoid;
    return await Result.guard(
      () =>
          notes.saveNote(id, title: trimmedTitle, body: body, now: clock.now()),
      onError: _storage,
    );
  }

  Future<Result<void>> move({
    required String id,
    required String? targetFolderId,
  }) async {
    if (targetFolderId != null &&
        await vault.getFolder(targetFolderId) == null) {
      return const Err(NotFoundFailure('Target folder not found'));
    }
    return await Result.guard(
      () => notes.moveNote(id, targetFolderId, clock.now()),
      onError: _storage,
    );
  }

  Future<Result<void>> delete(String id) =>
      Result.guard(() => notes.deleteNote(id, clock.now()), onError: _storage);

  Future<Result<List<Note>>> search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Ok([]));
    return Result.guard(() => notes.search(trimmed), onError: _storage);
  }

  static Failure _storage(Object error, StackTrace stackTrace) =>
      StorageFailure(error.toString(), cause: error, stackTrace: stackTrace);
}
