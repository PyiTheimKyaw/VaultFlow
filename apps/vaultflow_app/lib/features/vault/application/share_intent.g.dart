// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Feedback from the last share-sheet import, for a snackbar.

@ProviderFor(ShareImportResults)
final shareImportResultsProvider = ShareImportResultsProvider._();

/// Feedback from the last share-sheet import, for a snackbar.
final class ShareImportResultsProvider
    extends $NotifierProvider<ShareImportResults, List<Result<Document>>> {
  /// Feedback from the last share-sheet import, for a snackbar.
  ShareImportResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareImportResultsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareImportResultsHash();

  @$internal
  @override
  ShareImportResults create() => ShareImportResults();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Result<Document>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Result<Document>>>(value),
    );
  }
}

String _$shareImportResultsHash() =>
    r'5ec2335ca850aa93fd20eec93940b8d3c249d35c';

/// Feedback from the last share-sheet import, for a snackbar.

abstract class _$ShareImportResults extends $Notifier<List<Result<Document>>> {
  List<Result<Document>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<Result<Document>>, List<Result<Document>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Result<Document>>, List<Result<Document>>>,
              List<Result<Document>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(shareIntentImporter)
final shareIntentImporterProvider = ShareIntentImporterProvider._();

final class ShareIntentImporterProvider
    extends
        $FunctionalProvider<
          ShareIntentImporter?,
          ShareIntentImporter?,
          ShareIntentImporter?
        >
    with $Provider<ShareIntentImporter?> {
  ShareIntentImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareIntentImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareIntentImporterHash();

  @$internal
  @override
  $ProviderElement<ShareIntentImporter?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareIntentImporter? create(Ref ref) {
    return shareIntentImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareIntentImporter? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareIntentImporter?>(value),
    );
  }
}

String _$shareIntentImporterHash() =>
    r'b857ef23e83a83bd45b106615abe283b8cac1ab7';
