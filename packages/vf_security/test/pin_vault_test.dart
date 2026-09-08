import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_security/vf_security.dart';

void main() {
  late InMemorySecureStore store;
  late FakeClock clock;
  late PinVault vault;

  setUp(() {
    store = InMemorySecureStore();
    clock = FakeClock(DateTime.utc(2026, 9, 6));
    vault = PinVault(
      store,
      clock: clock,
      random: Random(1),
      memoryKiB: 64,
      iterations: 1,
    );
  });

  test('set, verify and clear', () async {
    expect(await vault.hasPin, isFalse);
    await vault.setPin('1234');
    expect(await vault.hasPin, isTrue);
    expect(store.values[PinVault.hashKey], isNot(contains('1234')));
    expect(await vault.verify('1234'), isA<PinOk>());
    expect(await vault.verify('0000'), isA<PinWrong>());
    await vault.clear();
    expect(await vault.hasPin, isFalse);
  });

  test('validates PIN shape', () async {
    expect(() => vault.setPin('12'), throwsA(isA<ValidationFailure>()));
    expect(() => vault.setPin('12ab'), throwsA(isA<ValidationFailure>()));
    expect(() => vault.setPin('123456789'), throwsA(isA<ValidationFailure>()));
  });

  test('locks out after five wrong guesses with doubling backoff', () async {
    await vault.setPin('2468');
    for (var i = 1; i < 5; i++) {
      final result = await vault.verify('0000');
      expect(result, isA<PinWrong>());
      expect((result as PinWrong).remainingAttempts, 5 - i);
    }
    final locked = await vault.verify('0000');
    expect(locked, isA<PinLockedOut>());
    expect(
      (locked as PinLockedOut).until,
      clock.now().add(const Duration(seconds: 30)),
    );
    // Even the right PIN is refused during the lockout.
    expect(await vault.verify('2468'), isA<PinLockedOut>());

    clock.advance(const Duration(seconds: 31));
    for (var i = 0; i < 5; i++) {
      await vault.verify('0000');
    }
    final second = await vault.verify('0000');
    expect(
      (second as PinLockedOut).until,
      clock.now().add(const Duration(seconds: 60)),
    );

    clock.advance(const Duration(minutes: 2));
    expect(await vault.verify('2468'), isA<PinOk>());
    // Success resets every counter.
    expect(store.values.containsKey(PinVault.attemptsKey), isFalse);
    expect(store.values.containsKey(PinVault.roundsKey), isFalse);
  });

  test('lockout is capped at the maximum', () async {
    final capped = PinVault(
      store,
      clock: clock,
      random: Random(2),
      memoryKiB: 64,
      iterations: 1,
      maxAttempts: 1,
      maxLockout: const Duration(seconds: 45),
    );
    await capped.setPin('1111');
    var until = clock.now();
    for (var round = 0; round < 4; round++) {
      clock.set(until.add(const Duration(seconds: 1)));
      until = ((await capped.verify('0000')) as PinLockedOut).until;
    }
    expect(until.difference(clock.now()), const Duration(seconds: 45));
  });
}
