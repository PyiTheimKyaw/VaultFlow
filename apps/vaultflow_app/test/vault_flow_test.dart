import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

Future<void> _createFolder(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('vault-new-folder')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('name-field')), name);
  await tester.tap(find.byKey(const Key('name-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  testApp('create, open, rename and delete a folder offline', (tester) async {
    final app = await TestApp.pump(tester);
    await _createFolder(tester, 'Projects');

    expect(find.text('Projects'), findsWidgets);
    expect(find.byKey(const Key('vault-root')), findsOneWidget);
    // Sidebar tree shows it too.
    final folders = await app.folders();
    final folder = folders.single;
    expect(find.byKey(Key('tree-${folder.id}')), findsOneWidget);
    // Header badge flips to pending because the outbox has one row.
    expect(await app.outboxCount(), 1);

    // Open it via the list tile.
    await tester.tap(find.byKey(Key('item-${folder.id}')));
    await tester.pumpAndSettle();
    expect(app.location, '/vault/${folder.id}');
    expect(find.byKey(Key('vault-${folder.id}-empty')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('breadcrumb')),
        matching: find.text('Projects'),
      ),
      findsOneWidget,
    );

    // Nested folder, then back to root through the breadcrumb.
    await _createFolder(tester, 'Sub');
    expect(find.byKey(Key('vault-${folder.id}')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('breadcrumb')),
        matching: find.text('Vault'),
      ),
    );
    await tester.pumpAndSettle();
    expect(app.location, '/vault');

    // Rename through the item menu.
    await tester.tap(find.byKey(Key('item-menu-${folder.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Work');
    await tester.tap(find.byKey(const Key('name-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsWidgets);
    expect(find.text('Projects'), findsNothing);

    // Delete cascades to the subfolder and queues both deletes... but since
    // nothing was ever synced, create+delete cancel out and the outbox
    // ends up empty.
    await tester.tap(find.byKey(Key('item-menu-${folder.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vault-root-empty')), findsOneWidget);
    expect(await app.outboxCount(), 0);
  });

  testApp('move a folder using the picker and refuse cycles', (tester) async {
    final app = await TestApp.pump(tester);
    await _createFolder(tester, 'A');
    await _createFolder(tester, 'B');
    final folders = await app.folders();
    final a = folders.firstWhere((f) => f.name == 'A');
    final b = folders.firstWhere((f) => f.name == 'B');

    await tester.tap(find.byKey(Key('item-menu-${b.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    // The folder being moved is disabled in the picker.
    final selfTile = tester.widget<ListTile>(find.byKey(Key('move-${b.id}')));
    expect(selfTile.enabled, isFalse);
    await tester.tap(find.byKey(Key('move-${a.id}')));
    await tester.pumpAndSettle();

    final moved = await app.container
        .read(vaultRepositoryProvider)
        .getFolder(b.id);
    expect(moved!.parentId, a.id);
    // Root now only shows A.
    expect(find.byKey(Key('item-${a.id}')), findsOneWidget);
    expect(find.byKey(Key('item-${b.id}')), findsNothing);
  });

  testApp('new note from the vault opens the editor in that folder', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    await _createFolder(tester, 'Ideas');
    final folder = (await app.folders()).single;
    app.go('/vault/${folder.id}');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('vault-new-note')));
    await tester.pumpAndSettle();
    expect(app.location, startsWith('/notes/'));
    final notes = await app.notes();
    expect(notes.single.folderId, folder.id);
    expect(find.byKey(Key('note-${notes.single.id}')), findsOneWidget);
  });

  testApp('grid view toggle and compact add menu', (tester) async {
    final app = await TestApp.pump(tester, size: const Size(400, 800));
    await tester.tap(find.byKey(const Key('vault-add-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vault-new-folder')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Phone');
    await tester.tap(find.byKey(const Key('name-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);

    await tester.tap(find.byKey(const Key('toggle-view')));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    final folder = (await app.folders()).single;
    expect(find.byKey(Key('item-${folder.id}')), findsOneWidget);
  });

  testApp('outbox debug page lists queued ops with payloads', (tester) async {
    final app = await TestApp.pump(tester);
    await _createFolder(tester, 'Queued');
    app.go('/settings/outbox');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outbox-list')), findsOneWidget);
    expect(find.text('1 queued'), findsOneWidget);
    expect(find.textContaining('CREATE folder'), findsOneWidget);
    final entries = await app.outboxEntries();
    expect(entries.single.op, SyncOp.create);
    await tester.tap(find.byKey(Key('outbox-${entries.single.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('"name": "Queued"'), findsOneWidget);
  });
}
