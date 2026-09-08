import 'dart:math';

import 'package:flutter/scheduler.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_security/vf_security.dart';

void main() {
  late FakeClock clock;
  late PinVault pin;
  late FakeBiometricGate biometrics;
  late InMemoryLockSettingsStore settings;
  late AppLockController controller;
  var notifications = 0;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 9, 6, 9));
    pin = PinVault(
      InMemorySecureStore(),
      clock: clock,
      random: Random(1),
      memoryKiB: 64,
      iterations: 1,
    );
    biometrics = FakeBiometricGate();
    settings = InMemoryLockSettingsStore(
      const LockSettings(
        timeout: Duration(minutes: 5),
        biometricsEnabled: true,
      ),
    );
    controller = AppLockController(
      pin: pin,
      biometrics: biometrics,
      settingsStore: settings,
      clock: clock,
    );
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  test('without a PIN the vault never locks', () async {
    await controller.initialize();
    expect(controller.isLocked, isFalse);
    controller
      ..handleLifecycle(AppLifecycleState.hidden)
      ..lock();
    clock.advance(const Duration(hours: 1));
    controller.handleLifecycle(AppLifecycleState.resumed);
    expect(controller.isLocked, isFalse);
  });

  test('cold start with a PIN is locked; PIN unlocks', () async {
    await pin.setPin('1234');
    await controller.initialize();
    expect(controller.isLocked, isTrue);
    expect(await controller.unlockWithPin('9999'), isA<PinWrong>());
    expect(controller.isLocked, isTrue);
    expect(await controller.unlockWithPin('1234'), isA<PinOk>());
    expect(controller.isLocked, isFalse);
  });

  test('locks only after the background timeout', () async {
    await pin.setPin('1234');
    await controller.initialize();
    await controller.unlockWithPin('1234');

    controller.handleLifecycle(AppLifecycleState.hidden);
    clock.advance(const Duration(minutes: 4));
    controller.handleLifecycle(AppLifecycleState.resumed);
    expect(controller.isLocked, isFalse, reason: 'under the timeout');

    controller.handleLifecycle(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 5));
    controller.handleLifecycle(AppLifecycleState.resumed);
    expect(controller.isLocked, isTrue, reason: 'at the timeout');
  });

  test('immediate timeout locks on any background trip', () async {
    await pin.setPin('1234');
    await controller.initialize();
    await controller.unlockWithPin('1234');
    await controller.updateSettings(const LockSettings());
    controller
      ..handleLifecycle(AppLifecycleState.hidden)
      ..handleLifecycle(AppLifecycleState.resumed);
    expect(controller.isLocked, isTrue);
  });

  test('inactive obscures the UI without locking', () async {
    await pin.setPin('1234');
    await controller.initialize();
    await controller.unlockWithPin('1234');
    controller.handleLifecycle(AppLifecycleState.inactive);
    expect(controller.isObscured, isTrue);
    expect(controller.isLocked, isFalse);
    controller.handleLifecycle(AppLifecycleState.resumed);
    expect(controller.isObscured, isFalse);
  });

  test('biometrics unlock when enabled and available', () async {
    await pin.setPin('1234');
    await controller.initialize();
    expect(controller.canUseBiometrics, isTrue);
    expect(await controller.unlockWithBiometrics(), isTrue);
    expect(controller.isLocked, isFalse);
    expect(biometrics.prompts, 1);
  });

  test('biometrics are refused when disabled, unavailable or failed', () async {
    await pin.setPin('1234');
    await controller.initialize();
    biometrics.succeed = false;
    expect(await controller.unlockWithBiometrics(), isFalse);
    expect(controller.isLocked, isTrue);

    biometrics.succeed = true;
    await controller.updateSettings(
      controller.settings.copyWith(biometricsEnabled: false),
    );
    expect(await controller.unlockWithBiometrics(), isFalse);

    await controller.updateSettings(
      controller.settings.copyWith(biometricsEnabled: true),
    );
    biometrics.result = BiometricAvailability.notEnrolled;
    await controller.refreshBiometricAvailability();
    expect(controller.canUseBiometrics, isFalse);
    expect(await controller.unlockWithBiometrics(), isFalse);
  });

  test('removing the PIN unlocks and disables biometrics', () async {
    await pin.setPin('1234');
    await controller.initialize();
    await controller.removePin();
    expect(controller.isLocked, isFalse);
    expect(controller.hasPin, isFalse);
    expect(settings.settings.biometricsEnabled, isFalse);
    expect(notifications, greaterThan(0));
  });
}
