// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_selection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Multi-select state for the folder view, keyed by id. Cleared on
/// navigation.

@ProviderFor(VaultSelection)
final vaultSelectionProvider = VaultSelectionProvider._();

/// Multi-select state for the folder view, keyed by id. Cleared on
/// navigation.
final class VaultSelectionProvider
    extends $NotifierProvider<VaultSelection, Map<String, VaultRef>> {
  /// Multi-select state for the folder view, keyed by id. Cleared on
  /// navigation.
  VaultSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultSelectionHash();

  @$internal
  @override
  VaultSelection create() => VaultSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, VaultRef> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, VaultRef>>(value),
    );
  }
}

String _$vaultSelectionHash() => r'd0df49bbc0491f58ff7d6504257b2c0aa184c350';

/// Multi-select state for the folder view, keyed by id. Cleared on
/// navigation.

abstract class _$VaultSelection extends $Notifier<Map<String, VaultRef>> {
  Map<String, VaultRef> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, VaultRef>, Map<String, VaultRef>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, VaultRef>, Map<String, VaultRef>>,
              Map<String, VaultRef>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(vaultBatchActions)
final vaultBatchActionsProvider = VaultBatchActionsProvider._();

final class VaultBatchActionsProvider
    extends
        $FunctionalProvider<
          VaultBatchActions,
          VaultBatchActions,
          VaultBatchActions
        >
    with $Provider<VaultBatchActions> {
  VaultBatchActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultBatchActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultBatchActionsHash();

  @$internal
  @override
  $ProviderElement<VaultBatchActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VaultBatchActions create(Ref ref) {
    return vaultBatchActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VaultBatchActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VaultBatchActions>(value),
    );
  }
}

String _$vaultBatchActionsHash() => r'239b6b231a248b8a59b77a250098fa285d0dc2a2';
