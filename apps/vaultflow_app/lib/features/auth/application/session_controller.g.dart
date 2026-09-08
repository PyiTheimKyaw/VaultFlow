// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Initial state computed in `main` from the keychain before the first
/// frame, so the router never sees a "restoring" limbo.

@ProviderFor(initialSession)
final initialSessionProvider = InitialSessionProvider._();

/// Initial state computed in `main` from the keychain before the first
/// frame, so the router never sees a "restoring" limbo.

final class InitialSessionProvider
    extends $FunctionalProvider<SessionState, SessionState, SessionState>
    with $Provider<SessionState> {
  /// Initial state computed in `main` from the keychain before the first
  /// frame, so the router never sees a "restoring" limbo.
  InitialSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialSessionHash();

  @$internal
  @override
  $ProviderElement<SessionState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionState create(Ref ref) {
    return initialSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$initialSessionHash() => r'bbb23a57585cd4770a7d5c987316dbe117d435bb';

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

final class SessionControllerProvider
    extends $NotifierProvider<SessionController, SessionState> {
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionControllerHash() => r'b07ee5bd7ef646fbea08467ec925b026c1fe1cb0';

abstract class _$SessionController extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
