import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/app.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
  bool signedIn = false,
}) async {
  await _setSize(tester, size);
  final container = ProviderContainer();
  addTearDown(container.dispose);
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
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  testWidgets('signed-out users land on /login', (tester) async {
    final container = await _pumpApp(tester);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(_location(container), '/login');
  });

  testWidgets('deep link is preserved through login', (tester) async {
    final container = await _pumpApp(tester);
    container.read(routerProvider).go('/notes/abc');
    await tester.pumpAndSettle();
    expect(_location(container), '/login?from=%2Fnotes%2Fabc');

    await tester.enterText(find.byKey(const Key('login-email')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('login-password')), 'pw');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(_location(container), '/notes/abc');
    expect(find.byKey(const Key('note-abc')), findsOneWidget);
  });

  testWidgets('invalid email keeps the user on the login page', (tester) async {
    final container = await _pumpApp(tester);
    await tester.enterText(find.byKey(const Key('login-email')), 'nope');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(_location(container), '/login');
  });

  testWidgets('expanded layout navigates via sidebar and keeps URLs', (
    tester,
  ) async {
    final container = await _pumpApp(tester, signedIn: true);
    expect(_location(container), '/vault');
    expect(find.byKey(const Key('vault-root')), findsOneWidget);
    expect(find.byKey(const Key('sidebar')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sidebar-nav-3')));
    await tester.pumpAndSettle();
    expect(_location(container), '/settings');
    expect(find.byKey(const Key('settings')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-nav-2')));
    await tester.pumpAndSettle();
    expect(_location(container), '/transfers');

    await tester.tap(find.text('Sample folder'));
    await tester.pumpAndSettle();
    expect(_location(container), '/vault/sample');
    expect(find.byKey(const Key('vault-sample')), findsOneWidget);
  });

  testWidgets('compact layout uses bottom navigation', (tester) async {
    final container = await _pumpApp(
      tester,
      size: const Size(400, 800),
      signedIn: true,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('sidebar')), findsNothing);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(_location(container), '/notes');

    await tester.tap(find.text('Open sample note'));
    await tester.pumpAndSettle();
    expect(_location(container), '/notes/sample');

    // Switching branches and back preserves the notes branch stack.
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    expect(_location(container), '/vault');
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(_location(container), '/notes/sample');
  });

  testWidgets('medium layout uses a navigation rail', (tester) async {
    await _pumpApp(tester, size: const Size(700, 900), signedIn: true);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sign out returns to /login', (tester) async {
    final container = await _pumpApp(tester, signedIn: true);
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(_location(container), '/login?from=%2Fsettings');
  });

  test('routes are registered under their public paths', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    for (final name in ['login', 'vault', 'folder', 'notes', 'note']) {
      expect(router.configuration.namedLocation, isNotNull, reason: name);
    }
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
  });
}
