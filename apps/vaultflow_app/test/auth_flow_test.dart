import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/features/auth/data/secure_token_store.dart';

import 'helpers/pump_app.dart';

Future<void> _fill(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
}

void main() {
  testApp('register creates an account and lands in the vault', (tester) async {
    final app = await TestApp.pump(tester, signedIn: false);
    expect(app.location, '/login');
    await tester.tap(find.byKey(const Key('login-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);

    await _fill(tester, 'New@Example.com', 'correct horse');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(app.location, '/vault');
    expect(app.server.users, containsPair('new@example.com', 'correct horse'));
    expect(app.secureStore.values[SecureTokenStore.key], contains('access-1'));
  });

  testApp('wrong password shows the server message and stays on login', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, signedIn: false);
    app.server.users['me@example.com'] = 'right';
    await _fill(tester, 'me@example.com', 'wrong pw');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(app.location, '/login');
    expect(find.text('Incorrect email or password'), findsOneWidget);
    expect(app.secureStore.values.containsKey(SecureTokenStore.key), isFalse);
  });

  testApp('offline sign-in explains the network problem', (tester) async {
    final app = await TestApp.pump(tester, signedIn: false);
    app.server.offline = true;
    await _fill(tester, 'me@example.com', 'whatever1');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cannot reach the server'), findsOneWidget);
  });

  testApp('a restored session starts in the vault without a login flash', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    expect(app.location, '/vault');
    expect(find.byKey(const Key('login-submit')), findsNothing);
  });

  testApp('sign out revokes on the server and wipes local data', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, initialLocation: '/settings');
    // Something to wipe.
    app.go('/vault');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vault-new-folder')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name-field')), 'Secret');
    await tester.tap(find.byKey(const Key('name-confirm')));
    await tester.pumpAndSettle();
    expect(await app.folders(), hasLength(1));

    app.go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-out-confirm')));
    await tester.pumpAndSettle();

    expect(app.location, '/login?from=%2Fsettings');
    expect(app.server.logouts, 1);
    expect(app.secureStore.values.containsKey(SecureTokenStore.key), isFalse);
    expect(await app.folders(), isEmpty);
    expect(await app.outboxCount(), 0);
  });
}
