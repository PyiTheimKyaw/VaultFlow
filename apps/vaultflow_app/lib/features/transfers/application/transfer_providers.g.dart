// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Created once per process; `main` calls `recover()` so transfers that
/// were running when the app died pick up where they stopped.

@ProviderFor(transferEngine)
final transferEngineProvider = TransferEngineProvider._();

/// Created once per process; `main` calls `recover()` so transfers that
/// were running when the app died pick up where they stopped.

final class TransferEngineProvider
    extends $FunctionalProvider<TransferEngine, TransferEngine, TransferEngine>
    with $Provider<TransferEngine> {
  /// Created once per process; `main` calls `recover()` so transfers that
  /// were running when the app died pick up where they stopped.
  TransferEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferEngineHash();

  @$internal
  @override
  $ProviderElement<TransferEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TransferEngine create(Ref ref) {
    return transferEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferEngine>(value),
    );
  }
}

String _$transferEngineHash() => r'ab76e551adaf3593a789d2d79e7847b4d29968de';

@ProviderFor(transferSessions)
final transferSessionsProvider = TransferSessionsProvider._();

final class TransferSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransferSessionRow>>,
          List<TransferSessionRow>,
          Stream<List<TransferSessionRow>>
        >
    with
        $FutureModifier<List<TransferSessionRow>>,
        $StreamProvider<List<TransferSessionRow>> {
  TransferSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<TransferSessionRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TransferSessionRow>> create(Ref ref) {
    return transferSessions(ref);
  }
}

String _$transferSessionsHash() => r'095b1c28b30a2b5ac5d858eb4c832114708b0279';

/// Live throughput per running session.

@ProviderFor(transferProgress)
final transferProgressProvider = TransferProgressProvider._();

/// Live throughput per running session.

final class TransferProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, TransferProgress>>,
          Map<String, TransferProgress>,
          Stream<Map<String, TransferProgress>>
        >
    with
        $FutureModifier<Map<String, TransferProgress>>,
        $StreamProvider<Map<String, TransferProgress>> {
  /// Live throughput per running session.
  TransferProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferProgressHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, TransferProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, TransferProgress>> create(Ref ref) {
    return transferProgress(ref);
  }
}

String _$transferProgressHash() => r'542eb04d34c08c122a517d59835df78d17f5d097';

/// Document name/size for each session (sessions store only ids).

@ProviderFor(transferDocuments)
final transferDocumentsProvider = TransferDocumentsProvider._();

/// Document name/size for each session (sessions store only ids).

final class TransferDocumentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DocumentRow>>,
          Map<String, DocumentRow>,
          FutureOr<Map<String, DocumentRow>>
        >
    with
        $FutureModifier<Map<String, DocumentRow>>,
        $FutureProvider<Map<String, DocumentRow>> {
  /// Document name/size for each session (sessions store only ids).
  TransferDocumentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferDocumentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferDocumentsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, DocumentRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, DocumentRow>> create(Ref ref) {
    return transferDocuments(ref);
  }
}

String _$transferDocumentsHash() => r'03975f4f5a651119da4b2d55378c0b3812de62d5';

/// Bytes the server did not need because the content already existed.

@ProviderFor(dedupeSavedBytes)
final dedupeSavedBytesProvider = DedupeSavedBytesProvider._();

/// Bytes the server did not need because the content already existed.

final class DedupeSavedBytesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Bytes the server did not need because the content already existed.
  DedupeSavedBytesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dedupeSavedBytesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dedupeSavedBytesHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return dedupeSavedBytes(ref);
  }
}

String _$dedupeSavedBytesHash() => r'6b37f3030e21a87dcaca8b3143dc5ed433bea15a';
