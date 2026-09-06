import 'package:vf_domain/src/entities/note.dart';

/// Notes. Same transactional outbox contract as `VaultRepository`.
abstract interface class NotesRepository {
  /// All live notes, most recently updated first.
  Stream<List<Note>> watchAllNotes();

  /// Live notes in one folder (`null` for the root), sorted by title.
  Stream<List<Note>> watchNotesIn(String? folderId);

  Stream<Note?> watchNote(String id);

  Future<Note?> getNote(String id);

  /// Full-text search over title and body; empty query returns nothing.
  Future<List<Note>> search(String query);

  Future<void> createNote(Note note);

  Future<void> saveNote(
    String id, {
    required String title,
    required String body,
    required DateTime now,
  });

  Future<void> moveNote(String id, String? folderId, DateTime now);

  Future<void> deleteNote(String id, DateTime now);
}
