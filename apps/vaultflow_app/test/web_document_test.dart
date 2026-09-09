import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_database/vf_database.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('on web, Download opens a signed link in the browser', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, web: true);
    final doc = await app.importDocument('sheet.csv', 'a,b');
    final session = (await app.transfers()).single;
    await app.settle<void>(
      DriftVaultRepository(app.db).attachStorageKey(
        doc.id,
        storageKey: 'u/me/ab/${doc.sha256}',
        transferId: session.id,
        version: 1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('item-${doc.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-offline')), findsNothing);
    await tester.tap(find.byKey(const Key('document-download-link')));
    await tester.pumpAndSettle();

    expect(app.server.downloadLinks, [doc.id]);
    expect(
      app.openedUrls.single.toString(),
      'https://api.test/documents/${doc.id}/content?token=signed-${doc.id}',
    );
  });

  testApp('a native Open launches the cached file', (tester) async {
    final app = await TestApp.pump(tester);
    final doc = await app.importDocument('notes.txt', 'hello');
    await tester.tap(find.byKey(Key('item-${doc.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-open')));
    await tester.pumpAndSettle();
    expect(app.openedUrls.single.scheme, 'file');
    expect(app.openedUrls.single.toFilePath(), doc.localPath);
  });
}
