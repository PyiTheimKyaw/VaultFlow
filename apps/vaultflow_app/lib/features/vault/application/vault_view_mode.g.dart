// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_view_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// List/grid toggle for the folder view, persisted in `app_settings`.

@ProviderFor(VaultViewModeController)
final vaultViewModeControllerProvider = VaultViewModeControllerProvider._();

/// List/grid toggle for the folder view, persisted in `app_settings`.
final class VaultViewModeControllerProvider
    extends $NotifierProvider<VaultViewModeController, VaultViewMode> {
  /// List/grid toggle for the folder view, persisted in `app_settings`.
  VaultViewModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultViewModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultViewModeControllerHash();

  @$internal
  @override
  VaultViewModeController create() => VaultViewModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VaultViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VaultViewMode>(value),
    );
  }
}

String _$vaultViewModeControllerHash() =>
    r'1d2847aaf3050bdd9146397e2a34cf56a6c0fb55';

/// List/grid toggle for the folder view, persisted in `app_settings`.

abstract class _$VaultViewModeController extends $Notifier<VaultViewMode> {
  VaultViewMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VaultViewMode, VaultViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VaultViewMode, VaultViewMode>,
              VaultViewMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which folders are expanded in the sidebar tree.

@ProviderFor(ExpandedFolders)
final expandedFoldersProvider = ExpandedFoldersProvider._();

/// Which folders are expanded in the sidebar tree.
final class ExpandedFoldersProvider
    extends $NotifierProvider<ExpandedFolders, Set<String>> {
  /// Which folders are expanded in the sidebar tree.
  ExpandedFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expandedFoldersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expandedFoldersHash();

  @$internal
  @override
  ExpandedFolders create() => ExpandedFolders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$expandedFoldersHash() => r'acfd9ad26b3943cc65789d3c5573d824eefeca56';

/// Which folders are expanded in the sidebar tree.

abstract class _$ExpandedFolders extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Width of the persistent sidebar on expanded layouts, persisted.

@ProviderFor(SidebarWidth)
final sidebarWidthProvider = SidebarWidthProvider._();

/// Width of the persistent sidebar on expanded layouts, persisted.
final class SidebarWidthProvider
    extends $NotifierProvider<SidebarWidth, double> {
  /// Width of the persistent sidebar on expanded layouts, persisted.
  SidebarWidthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarWidthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarWidthHash();

  @$internal
  @override
  SidebarWidth create() => SidebarWidth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$sidebarWidthHash() => r'8d5d1fedfbe5ee5dbbffeb3407a226a6a0c7facb';

/// Width of the persistent sidebar on expanded layouts, persisted.

abstract class _$SidebarWidth extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
