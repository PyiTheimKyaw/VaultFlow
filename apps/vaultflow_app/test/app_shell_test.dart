import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/router.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('signed-out users land on /login', (tester) async {
    final app = await TestApp.pump(tester, signedIn: false);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(app.location, '/login');
  });

  testApp('deep link is preserved through login', (tester) async {
    final app = await TestApp.pump(tester, signedIn: false);
    app.go('/notes/abc');
    await tester.pumpAndSettle();
    expect(app.location, '/login?from=%2Fnotes%2Fabc');

    await tester.enterText(find.byKey(const Key('login-email')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('login-password')), 'pw');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(app.location, '/notes/abc');
    // Unknown note id shows the not-found state instead of crashing.
    expect(find.byKey(const Key('note-missing')), findsOneWidget);
  });

  testApp('invalid email keeps the user on the login page', (tester) async {
    final app = await TestApp.pump(tester, signedIn: false);
    await tester.enterText(find.byKey(const Key('login-email')), 'nope');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(app.location, '/login');
  });

  testApp('expanded layout navigates via sidebar and keeps URLs', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    expect(app.location, '/vault');
    expect(find.byKey(const Key('vault-root-empty')), findsOneWidget);
    expect(find.byKey(const Key('sidebar')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sidebar-nav-3')));
    await tester.pumpAndSettle();
    expect(app.location, '/settings');
    expect(find.byKey(const Key('settings')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-nav-2')));
    await tester.pumpAndSettle();
    expect(app.location, '/transfers');

    await tester.tap(find.byKey(const Key('tree-root')));
    await tester.pumpAndSettle();
    expect(app.location, '/vault');
  });

  testApp('compact layout uses bottom navigation', (tester) async {
    final app = await TestApp.pump(tester, size: const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('sidebar')), findsNothing);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(app.location, '/notes');
    expect(find.byKey(const Key('notes-empty')), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(app.location, '/settings');
    await tester.tap(find.byKey(const Key('settings-outbox')));
    await tester.pumpAndSettle();
    expect(app.location, '/settings/outbox');
    expect(find.byKey(const Key('outbox-empty')), findsOneWidget);

    // Switching branches and back preserves the settings branch stack.
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    expect(app.location, '/vault');
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(app.location, '/settings/outbox');
  });

  testApp('medium layout uses a navigation rail', (tester) async {
    await TestApp.pump(tester, size: const Size(700, 900));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testApp('sign out returns to /login', (tester) async {
    final app = await TestApp.pump(tester, initialLocation: '/settings');
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(app.location, '/login?from=%2Fsettings');
  });

  test('routes are registered under their public paths', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    expect(
      router.configuration.namedLocation(
        'folder',
        pathParameters: {'folderId': 'x'},
      ),
      '/vault/x',
    );
    expect(
      router.configuration.namedLocation(
        'note',
        pathParameters: {'noteId': 'n'},
      ),
      '/notes/n',
    );
    expect(router.configuration.namedLocation('transfers'), '/transfers');
    expect(router.configuration.namedLocation('settings'), '/settings');
    expect(
      router.configuration.namedLocation('settings-outbox'),
      '/settings/outbox',
    );
  });
}
