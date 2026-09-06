import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

part 'di.g.dart';

/// The opened database. `main` overrides this once the encrypted database is
/// open; tests override it with an in-memory instance.
@Riverpod(keepAlive: true)
VaultFlowDatabase database(Ref ref) =>
    throw UnimplementedError('databaseProvider must be overridden');

@Riverpod(keepAlive: true)
VaultRepository vaultRepository(Ref ref) =>
    DriftVaultRepository(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
NotesRepository notesRepository(Ref ref) =>
    DriftNotesRepository(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
OutboxRepository outboxRepository(Ref ref) =>
    DriftOutboxRepository(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
VaultUseCases vaultUseCases(Ref ref) =>
    VaultUseCases(vault: ref.watch(vaultRepositoryProvider));

@Riverpod(keepAlive: true)
NotesUseCases notesUseCases(Ref ref) => NotesUseCases(
  notes: ref.watch(notesRepositoryProvider),
  vault: ref.watch(vaultRepositoryProvider),
);

// ------------------------------------------------------------ live queries

@riverpod
Stream<FolderContents> folderContents(Ref ref, String? folderId) =>
    ref.watch(vaultRepositoryProvider).watchContents(folderId);

@riverpod
Stream<List<Folder>> allFolders(Ref ref) =>
    ref.watch(vaultRepositoryProvider).watchAllFolders();

/// Root-first ancestor chain for [folderId], derived from the live folder
/// list so renames update breadcrumbs immediately.
@riverpod
List<Folder> breadcrumb(Ref ref, String? folderId) {
  if (folderId == null) return const [];
  final folders = ref.watch(allFoldersProvider).value ?? const [];
  final byId = {for (final f in folders) f.id: f};
  final chain = <Folder>[];
  final seen = <String>{};
  var current = byId[folderId];
  while (current != null && seen.add(current.id)) {
    chain.insert(0, current);
    current = current.parentId == null ? null : byId[current.parentId!];
  }
  return chain;
}

@riverpod
Stream<Folder?> folder(Ref ref, String id) =>
    ref.watch(vaultRepositoryProvider).watchFolder(id);

@riverpod
Stream<Document?> document(Ref ref, String id) =>
    ref.watch(vaultRepositoryProvider).watchDocument(id);

@riverpod
Stream<List<Note>> allNotes(Ref ref) =>
    ref.watch(notesRepositoryProvider).watchAllNotes();

@riverpod
Stream<Note?> note(Ref ref, String id) =>
    ref.watch(notesRepositoryProvider).watchNote(id);

@riverpod
Stream<List<OutboxEntry>> outboxEntries(Ref ref) =>
    ref.watch(outboxRepositoryProvider).watchAll();

@riverpod
Stream<int> outboxCount(Ref ref) =>
    ref.watch(outboxRepositoryProvider).watchPendingCount();
