// End-to-end: real app, real encrypted database, real HTTP against a running
// API (VAULTFLOW_API_BASE_URL, default http://localhost:8080).
//
//   scripts/dev_server.sh &
//   cd apps/vaultflow_app && flutter test integration_test -d macos
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vaultflow_app/app/app.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_security/vf_security.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login → create → sync → conflict → transfer', (tester) async {
    final email = 'e2e-${VfId.random()}@example.com';
    const password = 'correct horse battery staple';
    final tmp = Directory.systemTemp.createTempSync('vf_e2e_');
    final secure = InMemorySecureStore();
    final db = await openVaultFlowDatabase(
      keyLoader: DbKeyProvider(secure).getOrCreate,
      name: 'e2e-${Random().nextInt(1 << 30)}',
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        secureStoreProvider.overrideWithValue(secure),
        cacheDirectoryProvider.overrideWithValue(_TempCache(tmp.path)),
        initialSessionProvider.overrideWithValue(const SignedOut()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      tmp.deleteSync(recursive: true);
    });
    await container.read(appLockControllerProvider).initialize();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VaultFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Register through the login page.
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login-email')), email);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-submit')));
    await _settle(
      tester,
      () => container.read(sessionControllerProvider).isSignedIn,
    );
    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      '/vault',
    );

    // 2. Create a folder and a note offline-first, then sync.
    final vault = container.read(vaultUseCasesProvider);
    final notes = container.read(notesUseCasesProvider);
    final folder = (await vault.createFolder(name: 'E2E')).getOrThrow();
    final note = (await notes.create(folderId: folder.id)).getOrThrow();
    await notes.save(id: note.id, title: 'Plan', body: 'from device A');
    await _syncNow(container);
    expect(await db.outboxDao.getAll(), isEmpty);

    // 3. A second device edits the same note on the server.
    final b = await _DeviceB.login(email: email, password: password);
    final remote = (await b.api.changes(since: 0)).getOrThrow().changes;
    final serverNote = remote.firstWhere((c) => c.entityId == note.id);
    await b.pushNoteUpdate(
      note.id,
      baseVersion: serverNote.version,
      snapshot: {...serverNote.payload, 'body': 'from device B'},
    );
    // Local edit on A against the old version → conflict on push.
    await notes.save(id: note.id, title: 'Plan', body: 'from device A again');
    await _syncNow(container);
    final conflicts = await db.conflictsDao.getUnresolved();
    expect(conflicts, hasLength(1));

    // 4. Resolve "keep theirs" through the UI.
    container.read(routerProvider).go('/settings/conflicts');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('conflict-${conflicts.single.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resolve-keep-remote')));
    await _settle(
      tester,
      () async => (await db.conflictsDao.getUnresolved()).isEmpty,
    );
    final resolved = (await container
        .read(notesRepositoryProvider)
        .watchNote(note.id)
        .first)!;
    expect(resolved.body, 'from device B');

    // 5. Import a file; it uploads in chunks; device B can download it.
    final bytes = List<int>.generate(
      3 * 1024 * 1024 + 17,
      (i) => (i * 7) % 256,
    );
    final imported =
        (await container
                .read(documentImporterProvider)
                .importOne(
                  importSourceFromBytes('blob.bin', bytes),
                  folderId: folder.id,
                ))
            .getOrThrow();
    await container
        .read(transferEngineProvider)
        .drain(timeout: const Duration(minutes: 2));
    await _syncNow(container);
    final stored = (await vault.vault.getDocument(imported.id))!;
    expect(stored.storageKey, isNotNull);
    final download = (await b.api.downloadContent(imported.id)).getOrThrow();
    final got = <int>[];
    await download.stream.forEach(got.addAll);
    expect(got.length, bytes.length);
    expect(download.etag, stored.sha256);
  });
}

Future<void> _syncNow(ProviderContainer container) async {
  final report = await container
      .read(syncCoordinatorProvider.notifier)
      .syncNow();
  expect(report?.isOk, isTrue, reason: '${report?.failure}');
}

Future<void> _settle(
  WidgetTester tester,
  FutureOr<bool> Function() done,
) async {
  for (var i = 0; i < 300; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (await done()) return;
  }
  fail('condition not met in time');
}

class _TempCache implements CacheDirectory {
  const _TempCache(this.root);
  final String root;
  @override
  Future<String> cacheRoot() async => root;
}

/// A bare API client for the "other device".
class _DeviceB {
  _DeviceB._(this.api, this.deviceId);

  final ApiClient api;
  final String deviceId;

  static Future<_DeviceB> login({
    required String email,
    required String password,
  }) async {
    final tokens = InMemoryTokenStore();
    final api = ApiClient(
      DioFactory.create(baseUrl: apiBaseUrl, tokens: tokens, onAuthLost: () {}),
    );
    final auth = (await api.login(
      CredentialsRequest(
        email: email,
        password: password,
        deviceName: 'device B',
        platform: 'macos',
      ),
    )).getOrThrow();
    await tokens.write(auth);
    return _DeviceB._(api, auth.deviceId);
  }

  Future<void> pushNoteUpdate(
    String noteId, {
    required int baseVersion,
    required Map<String, Object?> snapshot,
  }) async {
    final response = (await api.push(
      PushRequest(
        deviceId: deviceId,
        ops: [
          SyncOpRequest(
            clientOpId: VfId.random(),
            entityType: EntityType.note,
            entityId: noteId,
            op: SyncOp.update,
            baseVersion: baseVersion,
            payload: snapshot,
          ),
        ],
      ),
    )).getOrThrow();
    expect(response.results.single.status, SyncOpStatus.applied);
  }
}
