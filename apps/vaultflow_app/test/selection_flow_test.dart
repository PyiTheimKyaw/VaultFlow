import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/vault/application/vault_selection.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('long-press selects, the bar batches move and delete', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    final b = (await app.settle(vault.createFolder(name: 'B'))).getOrThrow();
    final doc = await app.importDocument('c.txt', 'c');
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(Key('item-${b.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-bar')), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(Key('item-check-${b.id}')), findsOneWidget);

    // With a selection active, a plain tap toggles instead of opening.
    await tester.tap(find.byKey(Key('item-${doc.id}')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(app.location, '/vault');

    // Move both into A.
    await tester.tap(find.byKey(const Key('selection-move')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('move-${a.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('selection-bar')), findsNothing);
    final repo = app.container.read(vaultRepositoryProvider);
    expect((await app.settle(repo.getFolder(b.id)))!.parentId, a.id);
    expect((await app.settle(repo.getDocument(doc.id)))!.folderId, a.id);
    expect(find.text('Moved 2 items'), findsOneWidget);

    // Select all in A and delete.
    app.go('/vault/${a.id}');
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(Key('item-${b.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selection-all')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('selection-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete "2 items"?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('vault-${a.id}-empty')), findsOneWidget);
    expect(await app.settle(repo.getFolder(b.id)), isNull);
  });

  testApp('Escape clears and navigation resets the selection', (tester) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(Key('item-${a.id}')));
    await tester.pumpAndSettle();
    expect(app.container.read(vaultSelectionProvider), hasLength(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(app.container.read(vaultSelectionProvider), isEmpty);

    await tester.longPress(find.byKey(Key('item-${a.id}')));
    await tester.pumpAndSettle();
    app.go('/vault/${a.id}');
    await tester.pumpAndSettle();
    expect(app.container.read(vaultSelectionProvider), isEmpty);
  });

  testApp('keyboard shortcuts: ⌘N note, ⌘⇧N folder, ⌘F search', (tester) async {
    final app = await TestApp.pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(app.location, startsWith('/notes/'));
    expect(await app.notes(), hasLength(1));

    app.go('/vault');
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(find.text('New folder'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, 'Shortcut');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect((await app.folders()).map((f) => f.name), contains('Shortcut'));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(app.location, '/search');
  });

  testApp('right-click opens the context menu', (tester) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(Key('item-${a.id}'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('vault-root')),
        matching: find.text('Renamed'),
      ),
      findsOneWidget,
    );
  });

  testApp('touch: long-press-and-move drags an item onto a folder', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    final doc = await app.importDocument('d.txt', 'd');
    await tester.pumpAndSettle();

    final from = tester.getCenter(find.byKey(Key('item-${doc.id}')));
    final to = tester.getCenter(find.byKey(Key('item-${a.id}')));
    final gesture = await tester.startGesture(from);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(to);
    await tester.pump();
    // The hovered folder row is highlighted.
    final tile = tester.widget<ListTile>(find.byKey(Key('item-${a.id}')));
    expect(tile.tileColor, isNotNull);
    await gesture.up();
    await tester.pumpAndSettle();

    final repo = app.container.read(vaultRepositoryProvider);
    expect((await app.settle(repo.getDocument(doc.id)))!.folderId, a.id);
    expect(find.text('Moved 1 item'), findsOneWidget);
    expect(app.container.read(vaultSelectionProvider), isEmpty);
  });

  testApp('desktop: the mouse drags without a long press', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    final doc = await app.importDocument('d.txt', 'd');
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Key('item-${doc.id}'))),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(Key('item-${a.id}'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final repo = app.container.read(vaultRepositoryProvider);
    expect((await app.settle(repo.getDocument(doc.id)))!.folderId, a.id);
    // Must be restored before the framework's end-of-test check runs.
    debugDefaultTargetPlatformOverride = null;
  });

  testApp('the sidebar tree accepts drops too', (tester) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final a = (await app.settle(vault.createFolder(name: 'A'))).getOrThrow();
    final b = (await app.settle(vault.createFolder(name: 'B'))).getOrThrow();
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Key('item-${b.id}'))),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.byKey(Key('tree-${a.id}'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final repo = app.container.read(vaultRepositoryProvider);
    expect((await app.settle(repo.getFolder(b.id)))!.parentId, a.id);
    expect(app.container.read(vaultSelectionProvider), isEmpty);
    expect(SyncStatus.values, isNotEmpty);
  });
}
