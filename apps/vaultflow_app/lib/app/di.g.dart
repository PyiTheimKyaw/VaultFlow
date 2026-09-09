// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'di.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The opened database. `main` overrides this once the encrypted database is
/// open; tests override it with an in-memory instance.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The opened database. `main` overrides this once the encrypted database is
/// open; tests override it with an in-memory instance.

final class DatabaseProvider
    extends
        $FunctionalProvider<
          VaultFlowDatabase,
          VaultFlowDatabase,
          VaultFlowDatabase
        >
    with $Provider<VaultFlowDatabase> {
  /// The opened database. `main` overrides this once the encrypted database is
  /// open; tests override it with an in-memory instance.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<VaultFlowDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VaultFlowDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VaultFlowDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VaultFlowDatabase>(value),
    );
  }
}

String _$databaseHash() => r'326613321e64a3713162b8b0986c6011080c8d0c';

@ProviderFor(vaultRepository)
final vaultRepositoryProvider = VaultRepositoryProvider._();

final class VaultRepositoryProvider
    extends
        $FunctionalProvider<VaultRepository, VaultRepository, VaultRepository>
    with $Provider<VaultRepository> {
  VaultRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultRepositoryHash();

  @$internal
  @override
  $ProviderElement<VaultRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VaultRepository create(Ref ref) {
    return vaultRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VaultRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VaultRepository>(value),
    );
  }
}

String _$vaultRepositoryHash() => r'441c331d7fe1a0626047e107c29b99affeb57055';

@ProviderFor(notesRepository)
final notesRepositoryProvider = NotesRepositoryProvider._();

final class NotesRepositoryProvider
    extends
        $FunctionalProvider<NotesRepository, NotesRepository, NotesRepository>
    with $Provider<NotesRepository> {
  NotesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotesRepository create(Ref ref) {
    return notesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotesRepository>(value),
    );
  }
}

String _$notesRepositoryHash() => r'fca4678aae3fffe21b6cc70edb5e14ea9f1674f0';

@ProviderFor(outboxRepository)
final outboxRepositoryProvider = OutboxRepositoryProvider._();

final class OutboxRepositoryProvider
    extends
        $FunctionalProvider<
          OutboxRepository,
          OutboxRepository,
          OutboxRepository
        >
    with $Provider<OutboxRepository> {
  OutboxRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxRepositoryHash();

  @$internal
  @override
  $ProviderElement<OutboxRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OutboxRepository create(Ref ref) {
    return outboxRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutboxRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutboxRepository>(value),
    );
  }
}

String _$outboxRepositoryHash() => r'b68d8445ed64cf46482bf16c113cf4e2218f6bd1';

@ProviderFor(vaultUseCases)
final vaultUseCasesProvider = VaultUseCasesProvider._();

final class VaultUseCasesProvider
    extends $FunctionalProvider<VaultUseCases, VaultUseCases, VaultUseCases>
    with $Provider<VaultUseCases> {
  VaultUseCasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultUseCasesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultUseCasesHash();

  @$internal
  @override
  $ProviderElement<VaultUseCases> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VaultUseCases create(Ref ref) {
    return vaultUseCases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VaultUseCases value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VaultUseCases>(value),
    );
  }
}

String _$vaultUseCasesHash() => r'2e812fce7c3e0c475155ec3fd856879c14c82bfd';

@ProviderFor(notesUseCases)
final notesUseCasesProvider = NotesUseCasesProvider._();

final class NotesUseCasesProvider
    extends $FunctionalProvider<NotesUseCases, NotesUseCases, NotesUseCases>
    with $Provider<NotesUseCases> {
  NotesUseCasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesUseCasesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesUseCasesHash();

  @$internal
  @override
  $ProviderElement<NotesUseCases> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotesUseCases create(Ref ref) {
    return notesUseCases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotesUseCases value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotesUseCases>(value),
    );
  }
}

String _$notesUseCasesHash() => r'5a88382d3d350cf62addee30d452f150972f9ba4';

@ProviderFor(searchUseCases)
final searchUseCasesProvider = SearchUseCasesProvider._();

final class SearchUseCasesProvider
    extends $FunctionalProvider<SearchUseCases, SearchUseCases, SearchUseCases>
    with $Provider<SearchUseCases> {
  SearchUseCasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchUseCasesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchUseCasesHash();

  @$internal
  @override
  $ProviderElement<SearchUseCases> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchUseCases create(Ref ref) {
    return searchUseCases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchUseCases value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchUseCases>(value),
    );
  }
}

String _$searchUseCasesHash() => r'b96cb8e40f2845fb3793e432b1be47a36926dc5f';

/// Re-runs whenever the vault changes so results stay live while typing.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsFamily._();

/// Re-runs whenever the vault changes so results stay live while typing.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<FolderContents>,
          FolderContents,
          Stream<FolderContents>
        >
    with $FutureModifier<FolderContents>, $StreamProvider<FolderContents> {
  /// Re-runs whenever the vault changes so results stay live while typing.
  SearchResultsProvider._({
    required SearchResultsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchResultsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @override
  String toString() {
    return r'searchResultsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<FolderContents> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FolderContents> create(Ref ref) {
    final argument = this.argument as String;
    return searchResults(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchResultsHash() => r'f289de3c7ce4e1731caa3a40c266b19ffdfd5756';

/// Re-runs whenever the vault changes so results stay live while typing.

final class SearchResultsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<FolderContents>, String> {
  SearchResultsFamily._()
    : super(
        retry: null,
        name: r'searchResultsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Re-runs whenever the vault changes so results stay live while typing.

  SearchResultsProvider call(String query) =>
      SearchResultsProvider._(argument: query, from: this);

  @override
  String toString() => r'searchResultsProvider';
}

@ProviderFor(folderContents)
final folderContentsProvider = FolderContentsFamily._();

final class FolderContentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<FolderContents>,
          FolderContents,
          Stream<FolderContents>
        >
    with $FutureModifier<FolderContents>, $StreamProvider<FolderContents> {
  FolderContentsProvider._({
    required FolderContentsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'folderContentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$folderContentsHash();

  @override
  String toString() {
    return r'folderContentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<FolderContents> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FolderContents> create(Ref ref) {
    final argument = this.argument as String?;
    return folderContents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FolderContentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$folderContentsHash() => r'b4eabdedd3d1622c6b94a8916063a8a198ef049e';

final class FolderContentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<FolderContents>, String?> {
  FolderContentsFamily._()
    : super(
        retry: null,
        name: r'folderContentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FolderContentsProvider call(String? folderId) =>
      FolderContentsProvider._(argument: folderId, from: this);

  @override
  String toString() => r'folderContentsProvider';
}

@ProviderFor(allFolders)
final allFoldersProvider = AllFoldersProvider._();

final class AllFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Folder>>,
          List<Folder>,
          Stream<List<Folder>>
        >
    with $FutureModifier<List<Folder>>, $StreamProvider<List<Folder>> {
  AllFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allFoldersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allFoldersHash();

  @$internal
  @override
  $StreamProviderElement<List<Folder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Folder>> create(Ref ref) {
    return allFolders(ref);
  }
}

String _$allFoldersHash() => r'308c2b72fa94efbd2cdecdbe2240f1476c86ee2e';

/// Root-first ancestor chain for [folderId], derived from the live folder
/// list so renames update breadcrumbs immediately.

@ProviderFor(breadcrumb)
final breadcrumbProvider = BreadcrumbFamily._();

/// Root-first ancestor chain for [folderId], derived from the live folder
/// list so renames update breadcrumbs immediately.

final class BreadcrumbProvider
    extends $FunctionalProvider<List<Folder>, List<Folder>, List<Folder>>
    with $Provider<List<Folder>> {
  /// Root-first ancestor chain for [folderId], derived from the live folder
  /// list so renames update breadcrumbs immediately.
  BreadcrumbProvider._({
    required BreadcrumbFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'breadcrumbProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$breadcrumbHash();

  @override
  String toString() {
    return r'breadcrumbProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Folder>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Folder> create(Ref ref) {
    final argument = this.argument as String?;
    return breadcrumb(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Folder> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Folder>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BreadcrumbProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$breadcrumbHash() => r'12293806ecabf5cedd93a85ba4921ec5b6cbc487';

/// Root-first ancestor chain for [folderId], derived from the live folder
/// list so renames update breadcrumbs immediately.

final class BreadcrumbFamily extends $Family
    with $FunctionalFamilyOverride<List<Folder>, String?> {
  BreadcrumbFamily._()
    : super(
        retry: null,
        name: r'breadcrumbProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Root-first ancestor chain for [folderId], derived from the live folder
  /// list so renames update breadcrumbs immediately.

  BreadcrumbProvider call(String? folderId) =>
      BreadcrumbProvider._(argument: folderId, from: this);

  @override
  String toString() => r'breadcrumbProvider';
}

@ProviderFor(folder)
final folderProvider = FolderFamily._();

final class FolderProvider
    extends $FunctionalProvider<AsyncValue<Folder?>, Folder?, Stream<Folder?>>
    with $FutureModifier<Folder?>, $StreamProvider<Folder?> {
  FolderProvider._({
    required FolderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'folderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$folderHash();

  @override
  String toString() {
    return r'folderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Folder?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Folder?> create(Ref ref) {
    final argument = this.argument as String;
    return folder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FolderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$folderHash() => r'86187df23a65692a2b4811bce3fe4ccb932edbac';

final class FolderFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Folder?>, String> {
  FolderFamily._()
    : super(
        retry: null,
        name: r'folderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FolderProvider call(String id) => FolderProvider._(argument: id, from: this);

  @override
  String toString() => r'folderProvider';
}

@ProviderFor(document)
final documentProvider = DocumentFamily._();

final class DocumentProvider
    extends
        $FunctionalProvider<AsyncValue<Document?>, Document?, Stream<Document?>>
    with $FutureModifier<Document?>, $StreamProvider<Document?> {
  DocumentProvider._({
    required DocumentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentHash();

  @override
  String toString() {
    return r'documentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Document?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Document?> create(Ref ref) {
    final argument = this.argument as String;
    return document(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentHash() => r'3e616133658f37b3fc061751b54030d68fb66fa5';

final class DocumentFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Document?>, String> {
  DocumentFamily._()
    : super(
        retry: null,
        name: r'documentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DocumentProvider call(String id) =>
      DocumentProvider._(argument: id, from: this);

  @override
  String toString() => r'documentProvider';
}

@ProviderFor(allNotes)
final allNotesProvider = AllNotesProvider._();

final class AllNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          Stream<List<Note>>
        >
    with $FutureModifier<List<Note>>, $StreamProvider<List<Note>> {
  AllNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allNotesHash();

  @$internal
  @override
  $StreamProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Note>> create(Ref ref) {
    return allNotes(ref);
  }
}

String _$allNotesHash() => r'4c0d115fd2ded08152adeaf8dd8f20863935c7d4';

@ProviderFor(note)
final noteProvider = NoteFamily._();

final class NoteProvider
    extends $FunctionalProvider<AsyncValue<Note?>, Note?, Stream<Note?>>
    with $FutureModifier<Note?>, $StreamProvider<Note?> {
  NoteProvider._({
    required NoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteHash();

  @override
  String toString() {
    return r'noteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Note?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Note?> create(Ref ref) {
    final argument = this.argument as String;
    return note(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteHash() => r'5ca14d0c797b5b4e5667c2e1790172c094a5f9d1';

final class NoteFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Note?>, String> {
  NoteFamily._()
    : super(
        retry: null,
        name: r'noteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NoteProvider call(String id) => NoteProvider._(argument: id, from: this);

  @override
  String toString() => r'noteProvider';
}

@ProviderFor(outboxEntries)
final outboxEntriesProvider = OutboxEntriesProvider._();

final class OutboxEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutboxEntry>>,
          List<OutboxEntry>,
          Stream<List<OutboxEntry>>
        >
    with
        $FutureModifier<List<OutboxEntry>>,
        $StreamProvider<List<OutboxEntry>> {
  OutboxEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<OutboxEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OutboxEntry>> create(Ref ref) {
    return outboxEntries(ref);
  }
}

String _$outboxEntriesHash() => r'61089885456bde5e2dffa2e0c4cdd6ede8a6216a';

@ProviderFor(outboxCount)
final outboxCountProvider = OutboxCountProvider._();

final class OutboxCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  OutboxCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return outboxCount(ref);
  }
}

String _$outboxCountHash() => r'ed5e9b9a9b7aa88dafa4c3faa8a1feff93fe3fbe';

/// `kIsWeb`, as a provider so widget tests can exercise the web paths.

@ProviderFor(isWeb)
final isWebProvider = IsWebProvider._();

/// `kIsWeb`, as a provider so widget tests can exercise the web paths.

final class IsWebProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// `kIsWeb`, as a provider so widget tests can exercise the web paths.
  IsWebProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isWebProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isWebHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isWeb(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isWebHash() => r'096c0b10b8c13d276152c8cd850ef60542622497';

@ProviderFor(urlOpener)
final urlOpenerProvider = UrlOpenerProvider._();

final class UrlOpenerProvider
    extends $FunctionalProvider<UrlOpener, UrlOpener, UrlOpener>
    with $Provider<UrlOpener> {
  UrlOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlOpenerHash();

  @$internal
  @override
  $ProviderElement<UrlOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UrlOpener create(Ref ref) {
    return urlOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UrlOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UrlOpener>(value),
    );
  }
}

String _$urlOpenerHash() => r'f1e1e228ab20b32a3bf305cdd7830bcee10013a7';

@ProviderFor(secureStore)
final secureStoreProvider = SecureStoreProvider._();

final class SecureStoreProvider
    extends $FunctionalProvider<SecureStore, SecureStore, SecureStore>
    with $Provider<SecureStore> {
  SecureStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStoreHash();

  @$internal
  @override
  $ProviderElement<SecureStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecureStore create(Ref ref) {
    return secureStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureStore>(value),
    );
  }
}

String _$secureStoreHash() => r'd0c1df62496c756f4002545ad3d5d6e027fed66a';

@ProviderFor(tokenStore)
final tokenStoreProvider = TokenStoreProvider._();

final class TokenStoreProvider
    extends $FunctionalProvider<TokenStore, TokenStore, TokenStore>
    with $Provider<TokenStore> {
  TokenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStoreHash();

  @$internal
  @override
  $ProviderElement<TokenStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStore create(Ref ref) {
    return tokenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStore>(value),
    );
  }
}

String _$tokenStoreHash() => r'65a5b2075a5cc8340c669048155a9b876df0aaf0';

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

final class ConnectivityProvider
    extends
        $FunctionalProvider<
          ConnectivityMonitor,
          ConnectivityMonitor,
          ConnectivityMonitor
        >
    with $Provider<ConnectivityMonitor> {
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $ProviderElement<ConnectivityMonitor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityMonitor create(Ref ref) {
    return connectivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityMonitor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityMonitor>(value),
    );
  }
}

String _$connectivityHash() => r'827dbd2d4e75f08c59bf1763e89982e3e72d691c';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'2d8c114a66fa7626c25de2448ddac70c34847e1b';

@ProviderFor(pinVault)
final pinVaultProvider = PinVaultProvider._();

final class PinVaultProvider
    extends $FunctionalProvider<PinVault, PinVault, PinVault>
    with $Provider<PinVault> {
  PinVaultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinVaultProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinVaultHash();

  @$internal
  @override
  $ProviderElement<PinVault> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinVault create(Ref ref) {
    return pinVault(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinVault value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinVault>(value),
    );
  }
}

String _$pinVaultHash() => r'd8178650299475b40bc5f4f53a0dbb2c48a79f68';

@ProviderFor(biometricGate)
final biometricGateProvider = BiometricGateProvider._();

final class BiometricGateProvider
    extends $FunctionalProvider<BiometricGate, BiometricGate, BiometricGate>
    with $Provider<BiometricGate> {
  BiometricGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricGateHash();

  @$internal
  @override
  $ProviderElement<BiometricGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BiometricGate create(Ref ref) {
    return biometricGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricGate>(value),
    );
  }
}

String _$biometricGateHash() => r'536e996a9cc1e4b7f8e2602a71a2e97e31a5a480';

@ProviderFor(lockSettingsStore)
final lockSettingsStoreProvider = LockSettingsStoreProvider._();

final class LockSettingsStoreProvider
    extends
        $FunctionalProvider<
          LockSettingsStore,
          LockSettingsStore,
          LockSettingsStore
        >
    with $Provider<LockSettingsStore> {
  LockSettingsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockSettingsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockSettingsStoreHash();

  @$internal
  @override
  $ProviderElement<LockSettingsStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LockSettingsStore create(Ref ref) {
    return lockSettingsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockSettingsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockSettingsStore>(value),
    );
  }
}

String _$lockSettingsStoreHash() => r'9f6313d09dcce2479183cf7bed085b87f7a838ef';

/// Created once; `main` calls `initialize()` before the first frame.

@ProviderFor(appLockController)
final appLockControllerProvider = AppLockControllerProvider._();

/// Created once; `main` calls `initialize()` before the first frame.

final class AppLockControllerProvider
    extends
        $FunctionalProvider<
          AppLockController,
          AppLockController,
          AppLockController
        >
    with $Provider<AppLockController> {
  /// Created once; `main` calls `initialize()` before the first frame.
  AppLockControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockControllerHash();

  @$internal
  @override
  $ProviderElement<AppLockController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLockController create(Ref ref) {
    return appLockController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockController>(value),
    );
  }
}

String _$appLockControllerHash() => r'd89c6cdbe53aa314821e8853a43734354c2a577e';
