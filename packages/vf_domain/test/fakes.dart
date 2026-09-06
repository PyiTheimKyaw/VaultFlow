import 'dart:async';

import 'package:vf_domain/vf_domain.dart';

/// In-memory [VaultRepository] good enough for use-case tests. Streams are
/// not implemented; use-case tests only exercise the futures.
class FakeVaultRepository implements VaultRepository {
  final Map<String, Folder> folders = {};
  final Map<String, Document> documents = {};
  Exception? failNextWrite;

  void _maybeFail() {
    final error = failNextWrite;
    if (error != null) {
      failNextWrite = null;
      throw error;
    }
  }

  @override
  Future<Folder?> getFolder(String id) async {
    final folder = folders[id];
    return folder == null || folder.isDeleted ? null : folder;
  }

  @override
  Future<List<Folder>> getAncestors(String folderId) async {
    final chain = <Folder>[];
    var current = folders[folderId];
    while (current != null) {
      chain.insert(0, current);
      final parent = current.parentId;
      current = parent == null ? null : folders[parent];
    }
    return chain;
  }

  @override
  Future<void> createFolder(Folder folder) async {
    _maybeFail();
    folders[folder.id] = folder;
  }

  @override
  Future<void> renameFolder(String id, String name, DateTime now) async {
    _maybeFail();
    folders[id] = folders[id]!.copyWith(name: name, updatedAt: now);
  }

  @override
  Future<void> moveFolder(String id, String? parentId, DateTime now) async {
    _maybeFail();
    folders[id] = folders[id]!.copyWith(parentId: parentId, updatedAt: now);
  }

  @override
  Future<void> deleteFolder(String id, DateTime now) async {
    _maybeFail();
    folders[id] = folders[id]!.copyWith(deletedAt: now, updatedAt: now);
  }

  @override
  Future<void> createDocument(Document document) async {
    _maybeFail();
    documents[document.id] = document;
  }

  @override
  Future<void> renameDocument(String id, String name, DateTime now) async {
    documents[id] = documents[id]!.copyWith(name: name, updatedAt: now);
  }

  @override
  Future<void> moveDocument(String id, String? folderId, DateTime now) async {
    documents[id] = documents[id]!.copyWith(folderId: folderId, updatedAt: now);
  }

  @override
  Future<void> deleteDocument(String id, DateTime now) async {
    documents[id] = documents[id]!.copyWith(deletedAt: now, updatedAt: now);
  }

  @override
  Future<Document?> getDocument(String id) async => documents[id];

  @override
  Future<void> updateDocumentCache(
    String id, {
    required CacheState cacheState,
    String? localPath,
  }) async {
    documents[id] = documents[id]!.copyWith(
      cacheState: cacheState,
      localPath: localPath,
    );
  }

  @override
  Stream<List<Folder>> watchAllFolders() => throw UnimplementedError();

  @override
  Stream<FolderContents> watchContents(String? folderId) =>
      throw UnimplementedError();

  @override
  Stream<Document?> watchDocument(String id) => throw UnimplementedError();

  @override
  Stream<Folder?> watchFolder(String id) => throw UnimplementedError();
}

class FakeNotesRepository implements NotesRepository {
  final Map<String, Note> notes = {};
  int saveCalls = 0;

  @override
  Future<void> createNote(Note note) async => notes[note.id] = note;

  @override
  Future<Note?> getNote(String id) async => notes[id];

  @override
  Future<void> saveNote(
    String id, {
    required String title,
    required String body,
    required DateTime now,
  }) async {
    saveCalls++;
    notes[id] = notes[id]!.copyWith(title: title, body: body, updatedAt: now);
  }

  @override
  Future<void> moveNote(String id, String? folderId, DateTime now) async {
    notes[id] = notes[id]!.copyWith(folderId: folderId, updatedAt: now);
  }

  @override
  Future<void> deleteNote(String id, DateTime now) async {
    notes[id] = notes[id]!.copyWith(deletedAt: now, updatedAt: now);
  }

  @override
  Future<List<Note>> search(String query) async => notes.values
      .where((n) => !n.isDeleted)
      .where(
        (n) =>
            n.title.toLowerCase().contains(query.toLowerCase()) ||
            n.body.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  @override
  Stream<List<Note>> watchAllNotes() => throw UnimplementedError();

  @override
  Stream<Note?> watchNote(String id) => throw UnimplementedError();

  @override
  Stream<List<Note>> watchNotesIn(String? folderId) =>
      throw UnimplementedError();
}
