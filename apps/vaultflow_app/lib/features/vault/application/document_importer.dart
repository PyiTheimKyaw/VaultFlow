import 'dart:convert';
import 'dart:io' show File;

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

part 'document_importer.g.dart';

/// Where imported files live on this device.
abstract interface class CacheDirectory {
  Future<String> cacheRoot();
}

/// App-support directory (sandboxed, backed up, survives cache purges).
final class AppSupportCacheDirectory implements CacheDirectory {
  const AppSupportCacheDirectory();

  @override
  Future<String> cacheRoot() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'vaultflow', 'cache');
  }
}

/// One picked file, abstracted so tests can import without a file dialog.
class ImportSource {
  const ImportSource({required this.name, required this.bytes});

  ImportSource.fromPlatformFile(PlatformFile file)
    : name = file.name,
      bytes = file.readAsByteStream();

  final String name;
  final Stream<Uint8List> bytes;
}

/// Copies picked files into the local cache (hashing on the way) and
/// registers them as documents in the current folder.
///
/// Web has no writable filesystem, so the file is hashed and registered with
/// `cacheState = none`; its bytes are uploaded directly once transfers land
/// in Phase 5.
final class DocumentImporter {
  const DocumentImporter({
    required this.useCases,
    required this.cacheDirectory,
    this.isWeb = kIsWeb,
  });

  final VaultUseCases useCases;
  final CacheDirectory cacheDirectory;
  final bool isWeb;

  /// Opens the OS picker and imports every selected file.
  Future<List<Result<Document>>> pickAndImport({String? folderId}) async {
    final picked = await FilePicker.pickFiles(dialogTitle: 'Import files');
    if (picked.isEmpty) return const [];
    return await importAll(
      picked.map(ImportSource.fromPlatformFile),
      folderId: folderId,
    );
  }

  Future<List<Result<Document>>> importAll(
    Iterable<ImportSource> sources, {
    String? folderId,
  }) async {
    final results = <Result<Document>>[];
    for (final source in sources) {
      results.add(await importOne(source, folderId: folderId));
    }
    return results;
  }

  Future<Result<Document>> importOne(
    ImportSource source, {
    String? folderId,
  }) async {
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    var size = 0;
    String? localPath;

    try {
      if (isWeb) {
        await for (final chunk in source.bytes) {
          hasher.add(chunk);
          size += chunk.length;
        }
      } else {
        final root = await cacheDirectory.cacheRoot();
        final tmp = File(
          p.join(root, 'incoming', '${VfId.random()}-${source.name}'),
        );
        await tmp.parent.create(recursive: true);
        final sink = tmp.openWrite();
        try {
          await for (final chunk in source.bytes) {
            hasher.add(chunk);
            size += chunk.length;
            sink.add(chunk);
          }
        } finally {
          await sink.close();
        }
        hasher.close();
        final hash = digest.value.toString();
        // Content-addressed location: identical files share one copy.
        final finalFile = File(
          p.join(root, hash.substring(0, 2), hash, source.name),
        );
        await finalFile.parent.create(recursive: true);
        if (finalFile.existsSync()) {
          await tmp.delete();
        } else {
          await tmp.rename(finalFile.path);
        }
        localPath = finalFile.path;
        return await useCases.importDocument(
          name: source.name,
          mimeType: mimeTypeFor(source.name),
          sizeBytes: size,
          sha256: hash,
          folderId: folderId,
          localPath: localPath,
        );
      }
      hasher.close();
      return await useCases.importDocument(
        name: source.name,
        mimeType: mimeTypeFor(source.name),
        sizeBytes: size,
        sha256: digest.value.toString(),
        folderId: folderId,
      );
    } on Object catch (error, stackTrace) {
      return Err(
        StorageFailure(
          'Could not import ${source.name}: $error',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Collects the single [Digest] emitted by a chunked hash conversion.
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

@Riverpod(keepAlive: true)
CacheDirectory cacheDirectory(Ref ref) => const AppSupportCacheDirectory();

@Riverpod(keepAlive: true)
DocumentImporter documentImporter(Ref ref) => DocumentImporter(
  useCases: ref.watch(vaultUseCasesProvider),
  cacheDirectory: ref.watch(cacheDirectoryProvider),
);

/// Convenience for tests: an [ImportSource] over in-memory bytes.
ImportSource importSourceFromBytes(String name, List<int> bytes) =>
    ImportSource(name: name, bytes: Stream.value(Uint8List.fromList(bytes)));

/// Convenience for tests: an [ImportSource] over a UTF-8 string.
ImportSource importSourceFromString(String name, String text) =>
    importSourceFromBytes(name, utf8.encode(text));
