import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:vaultflow_app/app/app.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';

class TempCacheDirectory implements CacheDirectory {
  TempCacheDirectory(this.root);
  final String root;

  @override
  Future<String> cacheRoot() async => root;
}

/// A fully wired app on an in-memory database.
class TestApp {
  TestApp._(this.tester, this.container, this.db, this.cacheDir);

  final WidgetTester tester;
  final ProviderContainer container;
  final VaultFlowDatabase db;
  final Directory cacheDir;

  static Future<TestApp> pump(
    WidgetTester tester, {
    Size size = const Size(1200, 800),
    bool signedIn = true,
    String? initialLocation,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = openInMemoryDatabase();
    // Synchronous I/O only: widget tests run under fake async, where real
    // asynchronous file operations never complete.
    final cacheDir = Directory.systemTemp.createTempSync('vf_app_test_');
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        cacheDirectoryProvider.overrideWithValue(
          TempCacheDirectory(cacheDir.path),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      cacheDir.deleteSync(recursive: true);
    });
    if (signedIn) {
      container
          .read(sessionControllerProvider.notifier)
          .signInPlaceholder('me@example.com');
    }
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
    return TestApp._(tester, container, db, cacheDir);
  }

  String get location => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  void go(String location) => container.read(routerProvider).go(location);

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
