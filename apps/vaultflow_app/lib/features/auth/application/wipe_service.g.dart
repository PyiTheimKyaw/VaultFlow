// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wipe_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wipeService)
final wipeServiceProvider = WipeServiceProvider._();

final class WipeServiceProvider
    extends $FunctionalProvider<WipeService, WipeService, WipeService>
    with $Provider<WipeService> {
  WipeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wipeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wipeServiceHash();

  @$internal
  @override
  $ProviderElement<WipeService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WipeService create(Ref ref) {
    return wipeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WipeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WipeService>(value),
    );
  }
}

String _$wipeServiceHash() => r'ed06924b79fd46ff48361e8ab567e1073700bb92';
