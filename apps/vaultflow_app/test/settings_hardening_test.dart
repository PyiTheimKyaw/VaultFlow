import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/bootstrap.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('storage page measures the cache and frees uploaded copies', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final kept = await app.importDocument('keep.txt', 'not uploaded yet');
    final done = await app.importDocument('done.txt', 'x' * 2048);
    final session = (await app.transfers()).firstWhere(
      (s) => s.documentId == done.id,
    );
    await app.settle<void>(
      DriftVaultRepository(app.db).attachStorageKey(
        done.id,
        storageKey: 'u/me/ab/${done.sha256}',
        transferId: session.id,
        version: 1,
      ),
    );
    app.go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-storage')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('storage')), findsOneWidget);
    expect(find.byKey(Key('storage-doc-${done.id}')), findsOneWidget);
    expect(find.byKey(Key('storage-doc-${kept.id}')), findsNothing);
    expect(find.textContaining('2.0 KB'), findsWidgets);

    await tester.tap(find.byKey(const Key('storage-free-up')));
    await tester.pumpAndSettle();
    expect(find.text('Freed 2.0 KB'), findsOneWidget);
    expect(File(done.localPath!).existsSync(), isFalse);
    expect(File(kept.localPath!).existsSync(), isTrue);
    final repo = app.container.read(vaultRepositoryProvider);
    expect(
      (await app.settle(repo.getDocument(done.id)))!.cacheState,
      CacheState.none,
    );
    expect(find.text('Nothing to free'), findsOneWidget);
  });

  testApp('diagnostics page shows build info and the log tail', (tester) async {
    // `bootstrap()` installs the buffer in the real app; tests skip it.
    final previous = Logger.sink;
    Logger.sink = appLogBuffer;
    addTearDown(() => Logger.sink = previous);
    const Logger('test').warning('something odd', fields: {'n': 1});
    final app = await TestApp.pump(
      tester,
      initialLocation: '/settings/diagnostics',
    );
    expect(find.byKey(const Key('diagnostics')), findsOneWidget);
    expect(find.textContaining('0.7.0'), findsWidgets);
    expect(find.textContaining('something odd'), findsOneWidget);
    expect(
      appLogBuffer.records.any((r) => r.message == 'something odd'),
      isTrue,
    );
    // Capture what would land on the clipboard.
    Object? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied = call.arguments;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('diag-copy')));
    await tester.tap(find.byKey(const Key('diag-copy')));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics copied'), findsOneWidget);
    expect('${(copied! as Map)['text']}', contains('something odd'));
    expect('${(copied! as Map)['text']}', contains('VaultFlow 0.7.0'));
    expect(app.location, '/settings/diagnostics');
  });
}
