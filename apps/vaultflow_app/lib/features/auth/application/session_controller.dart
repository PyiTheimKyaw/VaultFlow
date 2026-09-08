import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/auth/application/device_info.dart';
import 'package:vaultflow_app/features/auth/application/wipe_service.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

part 'session_controller.g.dart';

const _log = Logger('session');

/// Who is signed in on this device.
sealed class SessionState {
  const SessionState();

  bool get isSignedIn => this is SignedIn;
  String? get email => switch (this) {
    SignedIn(:final email) => email,
    SignedOut() => null,
  };
}

final class SignedOut extends SessionState {
  const SignedOut();
}

final class SignedIn extends SessionState {
  const SignedIn({
    required this.userId,
    required this.deviceId,
    required this.email,
  });

  final String userId;
  final String deviceId;

  /// Known after login/register or `/auth/me`; may be null right after a
  /// cold-start restore until the profile is fetched.
  @override
  final String? email;
}

/// Initial state computed in `main` from the keychain before the first
/// frame, so the router never sees a "restoring" limbo.
@Riverpod(keepAlive: true)
SessionState initialSession(Ref ref) => const SignedOut();

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  SessionState build() {
    final initial = ref.watch(initialSessionProvider);
    if (initial is SignedIn && initial.email == null) {
      // Best effort: fill in the email and validate the token in the
      // background. Failures are handled by the auth interceptor.
      unawaited(Future<void>.microtask(_refreshProfile));
    }
    return initial;
  }

  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => _authenticate(
    (request) => ref.read(apiClientProvider).login(request),
    email: email,
    password: password,
  );

  Future<Result<void>> register({
    required String email,
    required String password,
  }) => _authenticate(
    (request) => ref.read(apiClientProvider).register(request),
    email: email,
    password: password,
  );

  Future<Result<void>> _authenticate(
    Future<Result<AuthTokens>> Function(CredentialsRequest request) call, {
    required String email,
    required String password,
  }) async {
    final previous = await ref.read(tokenStoreProvider).read();
    final result = await call(
      CredentialsRequest(
        email: email.trim(),
        password: password,
        deviceName: DeviceInfo.name,
        platform: DeviceInfo.platform,
        deviceId: previous?.deviceId,
      ),
    );
    switch (result) {
      case Ok(:final value):
        await ref.read(tokenStoreProvider).write(value);
        state = SignedIn(
          userId: value.userId,
          deviceId: value.deviceId,
          email: email.trim().toLowerCase(),
        );
        return okVoid;
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// Ends the session everywhere: revokes the refresh token family on the
  /// server (best effort) and wipes every local trace.
  Future<void> signOut() async {
    final tokens = await ref.read(tokenStoreProvider).read();
    if (tokens != null) {
      final result = await ref
          .read(apiClientProvider)
          .logout(
            RefreshRequest(
              refreshToken: tokens.refreshToken,
              deviceId: tokens.deviceId,
            ),
          );
      if (result.isErr) {
        _log.warning(
          'server logout failed; wiping locally anyway',
          error: result.failureOrNull,
        );
      }
    }
    await ref.read(wipeServiceProvider).wipeAll();
    state = const SignedOut();
  }

  /// Called by the network layer when a refresh fails: the server no longer
  /// trusts this device. Local data is kept so the user can sign back in.
  Future<void> onAuthLost() async {
    if (state is SignedOut) return;
    await ref.read(tokenStoreProvider).clear();
    state = const SignedOut();
  }

  Future<void> _refreshProfile() async {
    final result = await ref.read(apiClientProvider).me();
    if (result case Ok(:final value)) {
      if (state case SignedIn(:final userId, :final deviceId)) {
        state = SignedIn(
          userId: userId,
          deviceId: deviceId,
          email: value.email,
        );
      }
    }
  }
}
