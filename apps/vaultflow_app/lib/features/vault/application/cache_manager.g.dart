// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cacheManager)
final cacheManagerProvider = CacheManagerProvider._();

final class CacheManagerProvider
    extends $FunctionalProvider<CacheManager, CacheManager, CacheManager>
    with $Provider<CacheManager> {
  CacheManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheManagerHash();

  @$internal
  @override
  $ProviderElement<CacheManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheManager create(Ref ref) {
    return cacheManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheManager>(value),
    );
  }
}

String _$cacheManagerHash() => r'de2fe2df6b427a18930ed41c19b454299fc91141';

@ProviderFor(cacheUsage)
final cacheUsageProvider = CacheUsageProvider._();

final class CacheUsageProvider
    extends
        $FunctionalProvider<
          AsyncValue<CacheUsage>,
          CacheUsage,
          FutureOr<CacheUsage>
        >
    with $FutureModifier<CacheUsage>, $FutureProvider<CacheUsage> {
  CacheUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheUsageHash();

  @$internal
  @override
  $FutureProviderElement<CacheUsage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CacheUsage> create(Ref ref) {
    return cacheUsage(ref);
  }
}

String _$cacheUsageHash() => r'65b36a6dc0399953fc10ebd556ac91b72de843d8';
