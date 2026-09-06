// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_importer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cacheDirectory)
final cacheDirectoryProvider = CacheDirectoryProvider._();

final class CacheDirectoryProvider
    extends $FunctionalProvider<CacheDirectory, CacheDirectory, CacheDirectory>
    with $Provider<CacheDirectory> {
  CacheDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheDirectoryHash();

  @$internal
  @override
  $ProviderElement<CacheDirectory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheDirectory create(Ref ref) {
    return cacheDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheDirectory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheDirectory>(value),
    );
  }
}

String _$cacheDirectoryHash() => r'21eeeb6dfaf2817b942e48facd0bc651b41aa414';

@ProviderFor(documentImporter)
final documentImporterProvider = DocumentImporterProvider._();

final class DocumentImporterProvider
    extends
        $FunctionalProvider<
          DocumentImporter,
          DocumentImporter,
          DocumentImporter
        >
    with $Provider<DocumentImporter> {
  DocumentImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentImporterHash();

  @$internal
  @override
  $ProviderElement<DocumentImporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DocumentImporter create(Ref ref) {
    return documentImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentImporter>(value),
    );
  }
}

String _$documentImporterHash() => r'f46d88bf41fe48a847ed8524bf4370aa33834f2a';
