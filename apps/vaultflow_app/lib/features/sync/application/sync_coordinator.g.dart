// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the scheduler runs. Tests turn it off so widget tests do not
/// hit the network; the engine itself stays available for resolving.

@ProviderFor(syncEnabled)
final syncEnabledProvider = SyncEnabledProvider._();

/// Whether the scheduler runs. Tests turn it off so widget tests do not
/// hit the network; the engine itself stays available for resolving.

final class SyncEnabledProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the scheduler runs. Tests turn it off so widget tests do not
  /// hit the network; the engine itself stays available for resolving.
  SyncEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return syncEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncEnabledHash() => r'c2c1fafde162beb4c64708c79880bd7f348d0062';

/// Owns the engine and scheduler for the signed-in session: created on
/// sign-in, torn down on sign-out, kicked on app resume.

@ProviderFor(SyncCoordinator)
final syncCoordinatorProvider = SyncCoordinatorProvider._();

/// Owns the engine and scheduler for the signed-in session: created on
/// sign-in, torn down on sign-out, kicked on app resume.
final class SyncCoordinatorProvider
    extends $NotifierProvider<SyncCoordinator, SyncEngine?> {
  /// Owns the engine and scheduler for the signed-in session: created on
  /// sign-in, torn down on sign-out, kicked on app resume.
  SyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncCoordinatorHash();

  @$internal
  @override
  SyncCoordinator create() => SyncCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine?>(value),
    );
  }
}

String _$syncCoordinatorHash() => r'2fa50f6a14707577b9004decef9ad5df0ab477b5';

/// Owns the engine and scheduler for the signed-in session: created on
/// sign-in, torn down on sign-out, kicked on app resume.

abstract class _$SyncCoordinator extends $Notifier<SyncEngine?> {
  SyncEngine? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncEngine?, SyncEngine?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncEngine?, SyncEngine?>,
              SyncEngine?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Live engine state (phase, last sync, last error) as a stream.

@ProviderFor(syncState)
final syncStateProvider = SyncStateProvider._();

/// Live engine state (phase, last sync, last error) as a stream.

final class SyncStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncEngineState>,
          SyncEngineState,
          Stream<SyncEngineState>
        >
    with $FutureModifier<SyncEngineState>, $StreamProvider<SyncEngineState> {
  /// Live engine state (phase, last sync, last error) as a stream.
  SyncStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStateHash();

  @$internal
  @override
  $StreamProviderElement<SyncEngineState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SyncEngineState> create(Ref ref) {
    return syncState(ref);
  }
}

String _$syncStateHash() => r'42ad014bd5b57dfc99060f2e703d860638bc1827';

@ProviderFor(conflicts)
final conflictsProvider = ConflictsProvider._();

final class ConflictsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Conflict>>,
          List<Conflict>,
          Stream<List<Conflict>>
        >
    with $FutureModifier<List<Conflict>>, $StreamProvider<List<Conflict>> {
  ConflictsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictsHash();

  @$internal
  @override
  $StreamProviderElement<List<Conflict>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Conflict>> create(Ref ref) {
    return conflicts(ref);
  }
}

String _$conflictsHash() => r'c191e6a7d3f947b4e125c539def6eeb9069a3fc2';

@ProviderFor(failedOutboxCount)
final failedOutboxCountProvider = FailedOutboxCountProvider._();

final class FailedOutboxCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  FailedOutboxCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'failedOutboxCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$failedOutboxCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return failedOutboxCount(ref);
  }
}

String _$failedOutboxCountHash() => r'32e7cbccc6dd4c627b3f2ecb053520035778178f';
