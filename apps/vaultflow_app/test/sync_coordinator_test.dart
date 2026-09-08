import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('profile refresh keeps the same engine; sign-out disposes it', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final engine = app.container.read(syncCoordinatorProvider);
    expect(engine, isNotNull);

    // Same user and device, email filled in later: no rebuild.
    app.container
        .read(sessionControllerProvider.notifier)
        .state = const SignedIn(
      userId: 'user-me@example.com',
      deviceId: 'device-1',
      email: 'me@example.com',
    );
    await tester.pump();
    expect(
      identical(app.container.read(syncCoordinatorProvider), engine),
      isTrue,
    );
    expect(engine!.isDisposed, isFalse);

    await app.container.read(sessionControllerProvider.notifier).onAuthLost();
    await tester.pump();
    expect(app.container.read(syncCoordinatorProvider), isNull);
    expect(engine.isDisposed, isTrue);
  });
}
