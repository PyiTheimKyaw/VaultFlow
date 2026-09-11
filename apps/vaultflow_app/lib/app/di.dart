import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vaultflow_app/app/environment.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/auth/data/secure_token_store.dart';
import 'package:vaultflow_app/features/lock/application/lock_settings_store.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_security/vf_security.dart';

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

@Riverpod(keepAlive: true)
SearchUseCases searchUseCases(Ref ref) => SearchUseCases(
  vault: ref.watch(vaultRepositoryProvider),
  notes: ref.watch(notesRepositoryProvider),
);

// ------------------------------------------------------------ live queries

/// Re-runs whenever the vault changes so results stay live while typing.
@riverpod
Stream<FolderContents> searchResults(Ref ref, String query) {
  final db = ref.watch(databaseProvider);
  final search = ref.watch(searchUseCasesProvider);
  return db
      .customSelect('SELECT 1', readsFrom: {db.folders, db.documents, db.notes})
      .watch()
      .asyncMap((_) async => (await search.search(query)).getOrThrow());
}

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
Stream<List<Document>> allDocuments(Ref ref) =>
    ref.watch(vaultRepositoryProvider).watchAllDocuments();

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

// ------------------------------------------------------------ platform

/// `kIsWeb`, as a provider so widget tests can exercise the web paths.
@Riverpod(keepAlive: true)
bool isWeb(Ref ref) => kIsWeb;

/// Opens a URL with the OS (file viewer, browser download). Overridable so
/// tests can record launches instead of hitting the platform channel.
typedef UrlOpener = Future<bool> Function(Uri uri);

@Riverpod(keepAlive: true)
UrlOpener urlOpener(Ref ref) =>
    (uri) => launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );

/// API origin; see [AppEnvironment].
const String apiBaseUrl = AppEnvironment.apiBaseUrl;

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => KeychainSecureStore();

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) =>
    SecureTokenStore(ref.watch(secureStoreProvider));

@Riverpod(keepAlive: true)
ConnectivityMonitor connectivity(Ref ref) => PluginConnectivityMonitor();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(
  DioFactory.create(
    baseUrl: apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    logRequests: kDebugMode,
    onAuthLost: () => ref.read(sessionControllerProvider.notifier).onAuthLost(),
  ),
);

// ---------------------------------------------------------------- lock

@Riverpod(keepAlive: true)
PinVault pinVault(Ref ref) => PinVault(ref.watch(secureStoreProvider));

@Riverpod(keepAlive: true)
BiometricGate biometricGate(Ref ref) => kIsWeb
    ? FakeBiometricGate(result: BiometricAvailability.unsupported)
    : LocalAuthBiometricGate();

@Riverpod(keepAlive: true)
LockSettingsStore lockSettingsStore(Ref ref) =>
    DbLockSettingsStore(ref.watch(databaseProvider).settingsDao);

/// Created once; `main` calls `initialize()` before the first frame.
@Riverpod(keepAlive: true)
AppLockController appLockController(Ref ref) {
  final controller = AppLockController(
    pin: ref.watch(pinVaultProvider),
    biometrics: ref.watch(biometricGateProvider),
    settingsStore: ref.watch(lockSettingsStoreProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
}
