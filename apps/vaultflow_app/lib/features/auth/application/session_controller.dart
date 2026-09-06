import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

/// Minimal session model. Phase 3 replaces this with real tokens restored
/// from secure storage; the router only cares about [isSignedIn].
class SessionState {
  const SessionState({required this.isSignedIn, this.email});

  const SessionState.signedOut() : this(isSignedIn: false);

  final bool isSignedIn;
  final String? email;
}

@riverpod
class SessionController extends _$SessionController {
  @override
  SessionState build() => const SessionState.signedOut();

  /// Placeholder sign-in: accepts any non-empty email.
  void signInPlaceholder(String email) {
    state = SessionState(isSignedIn: true, email: email);
  }

  void signOut() => state = const SessionState.signedOut();
}
