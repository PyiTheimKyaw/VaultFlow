import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('search finds names and note text, and lives in the URL', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final vault = app.container.read(vaultUseCasesProvider);
    final notes = app.container.read(notesUseCasesProvider);
    final reports = await app.settle(vault.createFolder(name: 'Reports 2026'));
    await app.settle(vault.createFolder(name: 'Photos'));
    final note = await app.settle(notes.create());
    await app.settle(
      notes.save(
        id: note.getOrThrow().id,
        title: 'Groceries',
        body: 'keep the tax report receipt',
      ),
    );

    // From the app bar.
    await tester.tap(find.byKey(const Key('search-button')));
    await tester.pumpAndSettle();
    expect(app.location, '/search');
    expect(find.byKey(const Key('search-idle')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-field')), 'rep');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(app.location, '/search?q=rep');
    expect(find.byKey(const Key('search-results')), findsOneWidget);
    expect(find.byKey(Key('item-${reports.getOrThrow().id}')), findsOneWidget);
    expect(find.byKey(Key('item-${note.getOrThrow().id}')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('search-results')),
        matching: find.text('Photos'),
      ),
      findsNothing,
    );

    // Opening a hit keeps the vault destination selected.
    await tester.tap(find.byKey(Key('item-${reports.getOrThrow().id}')));
    await tester.pumpAndSettle();
    expect(app.location, '/vault/${reports.getOrThrow().id}');

    // Deep link with a query renders results directly.
    app.go('/search?q=zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pumpAndSettle();
    expect(app.location, '/search');
    expect(find.byKey(const Key('search-idle')), findsOneWidget);
  });

  testApp('search results update live and searches are safe', (tester) async {
    final app = await TestApp.pump(tester, initialLocation: '/search?q=%25');
    expect(find.byKey(const Key('search-empty')), findsOneWidget);
    final vault = app.container.read(vaultUseCasesProvider);
    final f = await app.settle(vault.createFolder(name: '100% done'));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('item-${f.getOrThrow().id}')), findsOneWidget);
    expect(f.getOrThrow().syncStatus, SyncStatus.pending);
  });
}
