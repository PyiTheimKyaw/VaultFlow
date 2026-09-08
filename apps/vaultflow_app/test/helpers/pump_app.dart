import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:vaultflow_app/app/app.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/auth/data/secure_token_store.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_security/vf_security.dart';

import 'fake_auth_server.dart';

class TempCacheDirectory implements CacheDirectory {
  TempCacheDirectory(this.root);
  final String root;

  @override
  Future<String> cacheRoot() async => root;
}

/// A fully wired app on an in-memory database, keychain and auth server.
class TestApp {
  TestApp._(
    this.tester,
    this.container,
    this.db,
    this.cacheDir,
    this.server,
    this.secureStore,
    this.biometrics,
    this.clock,
  );

  final WidgetTester tester;
  final ProviderContainer container;
  final VaultFlowDatabase db;
  final Directory cacheDir;
  final FakeAuthServer server;
  final InMemorySecureStore secureStore;
  final FakeBiometricGate biometrics;
  final FakeClock clock;

  static Future<TestApp> pump(
    WidgetTester tester, {
    Size size = const Size(1200, 800),
    bool signedIn = true,
    String? initialLocation,
    String? pin,
    LockSettings lockSettings = const LockSettings(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = openInMemoryDatabase();
    // Synchronous I/O only: widget tests run under fake async, where real
    // asynchronous file operations never complete.
    final cacheDir = Directory.systemTemp.createTempSync('vf_app_test_');
    final server = FakeAuthServer();
    final secureStore = InMemorySecureStore();
    final biometrics = FakeBiometricGate();
    final clock = FakeClock(DateTime.utc(2026, 9, 7, 9));
    final pinVault = PinVault(
      secureStore,
      clock: clock,
      random: Random(7),
      memoryKiB: 64,
      iterations: 1,
    );
    if (pin != null) await pinVault.setPin(pin);

    final tokenStore = SecureTokenStore(secureStore);
    late final ProviderContainer container;
    final apiClient = ApiClient(
      DioFactory.create(
        baseUrl: 'https://api.test',
        tokens: tokenStore,
        onAuthLost: () =>
            container.read(sessionControllerProvider.notifier).onAuthLost(),
      )..httpClientAdapter = server.adapter,
    );
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // No scheduler in widget tests: the fake server has no sync routes.
        syncEnabledProvider.overrideWithValue(false),
        tokenStoreProvider.overrideWithValue(tokenStore),
        apiClientProvider.overrideWithValue(apiClient),
        cacheDirectoryProvider.overrideWithValue(
          TempCacheDirectory(cacheDir.path),
        ),
        secureStoreProvider.overrideWithValue(secureStore),
        biometricGateProvider.overrideWithValue(biometrics),
        pinVaultProvider.overrideWithValue(pinVault),
        initialSessionProvider.overrideWithValue(
          signedIn
              ? const SignedIn(
                  userId: 'user-me@example.com',
                  deviceId: 'device-1',
                  email: 'me@example.com',
                )
              : const SignedOut(),
        ),
        appLockControllerProvider.overrideWith((ref) {
          final controller = AppLockController(
            pin: pinVault,
            biometrics: biometrics,
            settingsStore: ref.watch(lockSettingsStoreProvider),
            clock: clock,
          );
          ref.onDispose(controller.dispose);
          return controller;
        }),
      ],
    );
    if (signedIn) {
      await tokenStore.write(
        const AuthTokens(
          accessToken: 'access-0',
          refreshToken: 'refresh-0',
          deviceId: 'device-1',
          userId: 'user-me@example.com',
          expiresIn: 900,
        ),
      );
    }
    await container.read(lockSettingsStoreProvider).save(lockSettings);
    await container.read(appLockControllerProvider).initialize();

    addTearDown(() {
      container.dispose();
      // Sign-out wipes the cache directory itself.
      if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VaultFlowApp(),
      ),
    );
    if (initialLocation != null) {
      container.read(routerProvider).go(initialLocation);
    }
    await tester.pumpAndSettle();
    return TestApp._(
      tester,
      container,
      db,
      cacheDir,
      server,
      secureStore,
      biometrics,
      clock,
    );
  }

  String get location => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  void go(String location) => container.read(routerProvider).go(location);

  AppLockController get lock => container.read(appLockControllerProvider);

  /// Awaits a database future from inside a widget test.
  ///
  /// Widget tests run under fake async, so Drift's query results (delivered
  /// through the event loop) only arrive while the tester pumps.
  Future<T> settle<T>(Future<T> future) async {
    T? value;
    Object? error;
    StackTrace? stack;
    var done = false;
    unawaited(
      future.then(
        (v) {
          value = v;
          done = true;
        },
        onError: (Object e, StackTrace s) {
          error = e;
          stack = s;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (!done) {
      throw TimeoutException('database future did not complete');
    }
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    return value as T;
  }

  // Row-level lookups through the DAOs. Two things do not work from a
  // widget-test body: reading `.future` on an auto-dispose stream provider
  // (it is disposed while loading) and awaiting `.first` on a Drift stream
  // (it never emits under fake async). Plain query futures are fine.
  Future<List<FolderRow>> folders() => settle(db.foldersDao.getAllLive());

  Future<List<NoteRow>> notes() => settle(db.notesDao.getAllLive());

  Future<List<OutboxRow>> outboxEntries() => settle(db.outboxDao.getAll());

  Future<int> outboxCount() async => (await outboxEntries()).length;
}

/// [testWidgets] plus an extra pump after the body: Drift schedules a
/// zero-duration timer when a query stream is closed during provider
/// disposal, which flutter_test would otherwise flag as a leaked timer.
@isTest
void testApp(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    await callback(tester);
    await tester.pump();
    await tester.pumpAndSettle();
  });
}
