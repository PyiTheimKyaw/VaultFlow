import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_security/vf_security.dart';

import 'helpers/pump_app.dart';

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-$digit')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('pin-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testApp('without a PIN the vault is never locked', (tester) async {
    final app = await TestApp.pump(tester);
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    app.lock.handleLifecycle(AppLifecycleState.hidden);
    app.clock.advance(const Duration(hours: 2));
    app.lock.handleLifecycle(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsNothing);
  });

  testApp('cold start with a PIN shows the lock over the current route', (
    tester,
  ) async {
    final app = await TestApp.pump(
      tester,
      pin: '2468',
      initialLocation: '/notes',
    );
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    // The route underneath is preserved (URL survives locking).
    expect(app.location, '/notes');

    await _typePin(tester, '1111');
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);

    await _typePin(tester, '2468');
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    expect(app.location, '/notes');
  });

  testApp('backgrounding past the timeout locks; before it does not', (
    tester,
  ) async {
    final app = await TestApp.pump(
      tester,
      pin: '2468',
      lockSettings: const LockSettings(timeout: Duration(minutes: 5)),
    );
    await _typePin(tester, '2468');
    expect(find.byKey(const Key('lock-screen')), findsNothing);

    app.lock.handleLifecycle(AppLifecycleState.paused);
    app.clock.advance(const Duration(minutes: 2));
    app.lock.handleLifecycle(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsNothing);

    app.lock.handleLifecycle(AppLifecycleState.paused);
    app.clock.advance(const Duration(minutes: 5));
    app.lock.handleLifecycle(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
  });

  testApp('inactive shows the privacy cover', (tester) async {
    final app = await TestApp.pump(tester, pin: '2468');
    await _typePin(tester, '2468');
    app.lock.handleLifecycle(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(const Key('privacy-cover')), findsOneWidget);
    app.lock.handleLifecycle(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('privacy-cover')), findsNothing);
  });

  testApp('biometrics unlock when enabled', (tester) async {
    final app = await TestApp.pump(
      tester,
      pin: '2468',
      lockSettings: const LockSettings(biometricsEnabled: true),
    );
    // The lock screen prompts automatically on appearance.
    await tester.pumpAndSettle();
    expect(app.biometrics.prompts, 1);
    expect(find.byKey(const Key('lock-screen')), findsNothing);
  });

  testApp('lock settings page sets a PIN, enables biometrics and locks now', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, initialLocation: '/settings');
    await tester.tap(find.byKey(const Key('settings-lock')));
    await tester.pumpAndSettle();
    expect(app.location, '/settings/lock');

    await tester.tap(find.byKey(const Key('lock-set-pin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pin-first')), '1357');
    await tester.enterText(find.byKey(const Key('pin-second')), '1358');
    await tester.tap(find.byKey(const Key('pin-save')));
    await tester.pumpAndSettle();
    expect(find.text('PINs do not match'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pin-second')), '1357');
    await tester.tap(find.byKey(const Key('pin-save')));
    await tester.pumpAndSettle();
    expect(app.lock.hasPin, isTrue);
    expect(find.byKey(const Key('lock-screen')), findsNothing);

    await tester.tap(find.byKey(const Key('lock-biometrics')));
    await tester.pumpAndSettle();
    expect(app.lock.settings.biometricsEnabled, isTrue);

    await tester.tap(find.byKey(const Key('lock-now')));
    await tester.pump();
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    // The lock screen prompts for biometrics on appearance and succeeds.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    expect(app.biometrics.prompts, 1);
  });

  testApp('five wrong PINs lock out with a countdown', (tester) async {
    final app = await TestApp.pump(tester, pin: '2468');
    for (var i = 0; i < 5; i++) {
      await _typePin(tester, '0000');
    }
    expect(find.textContaining('Too many attempts'), findsOneWidget);
    // Digits are disabled during the lockout.
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('pin-1')),
    );
    expect(button.onPressed, isNull);
    app.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    await _typePin(tester, '2468');
    expect(find.byKey(const Key('lock-screen')), findsNothing);
  });
}
