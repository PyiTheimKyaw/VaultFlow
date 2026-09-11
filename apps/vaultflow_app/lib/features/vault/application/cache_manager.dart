import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

part 'cache_manager.g.dart';

const _log = Logger('cache');

/// Bytes on disk in the content-addressed cache and per-document usage.
class CacheUsage {
  const CacheUsage({required this.totalBytes, required this.evictable});

  final int totalBytes;

  /// Documents whose local copy can be dropped (the server has the bytes).
  final List<Document> evictable;

  int get evictableBytes => evictable.fold(0, (n, d) => n + d.sizeBytes);
}

/// Local copies of documents: measure, evict, and turn "disk full" into a
/// clear failure instead of a stack trace.
class CacheManager {
  const CacheManager({
    required this.vault,
    required this.cacheDirectory,
    this.isWeb = kIsWeb,
  });

  final VaultRepository vault;
  final CacheDirectory cacheDirectory;
  final bool isWeb;

  Future<CacheUsage> usage() async {
    var total = 0;
    if (!isWeb) {
      final root = Directory(await cacheDirectory.cacheRoot());
      // Synchronous on purpose: the cache is small and this also keeps the
      // page usable in widget tests, which run under fake async.
      if (root.existsSync()) {
        for (final entry in root.listSync(recursive: true)) {
          if (entry is File) total += entry.lengthSync();
        }
      }
    }
    final docs = await vault.listCachedDocuments();
    return CacheUsage(
      totalBytes: total,
      evictable: docs
          .where((d) => d.isUploaded && d.localPath != null)
          .toList(),
    );
  }

  /// Removes the local copy of [doc]; it stays downloadable.
  Future<Result<void>> evict(Document doc) async {
    final path = doc.localPath;
    if (!doc.isUploaded) {
      return const Err(
        ValidationFailure('This copy has not been uploaded yet'),
      );
    }
    try {
      if (path != null && !isWeb) {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      }
      await vault.updateDocumentCache(doc.id, cacheState: CacheState.none);
      return okVoid;
    } on Object catch (e, st) {
      return Err(
        StorageFailure(
          'Could not remove the copy: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Evicts every uploaded document's local copy. Returns bytes freed.
  Future<Result<int>> evictAll() async {
    final usage = await this.usage();
    var freed = 0;
    for (final doc in usage.evictable) {
      if ((await evict(doc)).isOk) freed += doc.sizeBytes;
    }
    _log.info('cache evicted', fields: {'bytes': freed});
    return Ok(freed);
  }

  /// `ENOSPC`/`EDQUOT` from the OS, reported as one human sentence.
  static bool isDiskFull(Object error) =>
      error is FileSystemException &&
      (error.osError?.errorCode == 28 || error.osError?.errorCode == 122);

  static const String diskFullMessage =
      'Not enough free space on this device. Free up space or remove '
      'offline copies in Settings › Storage.';
}

@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) => CacheManager(
  vault: ref.watch(vaultRepositoryProvider),
  cacheDirectory: ref.watch(cacheDirectoryProvider),
  isWeb: ref.watch(isWebProvider),
);

@riverpod
Future<CacheUsage> cacheUsage(Ref ref) {
  // Recompute whenever documents change.
  ref.watch(allDocumentsProvider);
  return ref.watch(cacheManagerProvider).usage();
}
