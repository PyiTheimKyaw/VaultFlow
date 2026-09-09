import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/transfers/application/transfer_providers.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('an imported document waits on its upload session', (tester) async {
    final app = await TestApp.pump(tester);
    final doc = await app.importDocument('report.pdf', 'pdf bytes');

    // The create is parked on the transfer instead of pushed immediately.
    final entries = await app.outboxEntries();
    final create = entries.single;
    expect(create.state, OutboxState.blocked);
    final sessions = await app.transfers();
    expect(sessions.single.documentId, doc.id);
    expect(create.dependsOnTransfer, sessions.single.id);
    expect(sessions.single.state, 'queued');
    expect(sessions.single.kind, 'upload');

    // Vault row shows it as local-only until the upload lands.
    expect(find.byKey(Key('item-${doc.id}')), findsOneWidget);
    await tester.tap(find.byKey(Key('item-${doc.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-sheet')), findsOneWidget);
    expect(find.text('Uploading…'), findsOneWidget);
    // The local copy can be opened, but it cannot be evicted before the
    // server has the bytes.
    final open = tester.widget<FilledButton>(
      find.byKey(const Key('document-open')),
    );
    expect(open.onPressed, isNotNull);
    expect(find.text('Open'), findsOneWidget);
    final offline = tester.widget<SwitchListTile>(
      find.byKey(const Key('document-offline')),
    );
    expect(offline.value, isTrue);
    expect(offline.onChanged, isNull);
  });

  testApp('transfers page lists the queue with pause, cancel and clear', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final doc = await app.importDocument('big.bin', 'x' * 4096);
    final session = (await app.transfers()).single;

    app.go('/transfers');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transfers-list')), findsOneWidget);
    expect(find.byKey(Key('transfer-${session.id}')), findsOneWidget);
    expect(find.text('big.bin'), findsOneWidget);
    expect(find.textContaining('Queued'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);

    await tester.tap(find.byKey(Key('transfer-pause-${session.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paused'), findsOneWidget);
    expect(find.byKey(Key('transfer-resume-${session.id}')), findsOneWidget);

    await tester.tap(find.byKey(Key('transfer-resume-${session.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Queued'), findsOneWidget);

    await tester.tap(find.byKey(Key('transfer-cancel-${session.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cancelled'), findsOneWidget);
    expect(find.text('0 active'), findsOneWidget);
    expect((await app.transfers()).single.state, 'cancelled');
    // The document itself is untouched; only its upload was abandoned.
    expect(await app.settle(app.db.documentsDao.getById(doc.id)), isNotNull);

    await tester.tap(find.byKey(const Key('transfers-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transfers')), findsOneWidget);
    expect(await app.transfers(), isEmpty);
  });

  testApp('keep offline toggle queues a download for an uploaded document', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final doc = await app.importDocument('notes.txt', 'remote copy');
    // Pretend the upload finished and the copy was evicted: the server has
    // the blob, this device does not.
    final session = (await app.transfers()).single;
    await app.settle<void>(
      DriftVaultRepository(app.db).attachStorageKey(
        doc.id,
        storageKey: 'u/me/ab/${doc.sha256}',
        transferId: session.id,
        version: 1,
      ),
    );
    await app.settle<void>(
      app.container
          .read(vaultRepositoryProvider)
          .updateDocumentCache(doc.id, cacheState: CacheState.none),
    );
    await app.settle<void>(
      app.db.transfersDao.setState(
        session.id,
        'completed',
        now: app.clock.now(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('item-${doc.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Uploaded'), findsOneWidget);
    expect(find.text('Not on this device'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.byKey(const Key('document-offline')));
    await tester.pumpAndSettle();
    final downloads = (await app.transfers()).where(
      (s) => s.kind == 'download',
    );
    expect(downloads.single.documentId, doc.id);
    expect(downloads.single.state, 'queued');
    expect(find.byKey(const Key('document-progress')), findsOneWidget);
    expect(find.textContaining('Downloading'), findsOneWidget);

    // The transfers badge counts it too.
    expect(app.container.read(transferSessionsProvider).value?.length ?? 0, 2);
  });
}
