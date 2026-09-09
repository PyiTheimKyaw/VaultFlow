import 'package:meta/meta.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/storage/storage_adapter.dart';
import 'package:vaultflow_server/sync/sync_store.dart';
import 'package:vaultflow_server/transfer/upload_store.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// A ranged read of a document's bytes.
@immutable
class ContentRange {
  const ContentRange({
    required this.start,
    required this.end,
    required this.total,
    required this.etag,
    required this.mimeType,
    required this.stream,
  });

  final int start;

  /// Inclusive.
  final int end;
  final int total;

  /// The document's sha256; changes only when the content changes.
  final String etag;
  final String mimeType;
  final Stream<List<int>> stream;

  int get length => end - start + 1;
  bool get isPartial => start != 0 || end != total - 1;
}

/// Serves `GET /documents/{id}/content` with `Range` support.
class ContentService {
  ContentService({
    required this.sync,
    required this.uploads,
    required this.storage,
  });

  final SyncStore sync;
  final UploadStore uploads;
  final StorageAdapter storage;

  static final RegExp _rangeHeader = RegExp(r'^bytes=(\d*)-(\d*)$');

  Future<ContentRange> read(
    String userId,
    String documentId, {
    String? rangeHeader,
  }) async {
    final document = await sync.find(userId, EntityType.document, documentId);
    if (document == null || document.isDeleted) {
      throw const ApiException.notFound('Document not found');
    }
    final key = document.snapshot['storage_key'];
    if (key is! String) {
      throw const ApiException.notFound('Document has no content yet');
    }
    final blob = await uploads.findBlobByKey(userId, key);
    if (blob == null) throw const ApiException.notFound('Content missing');
    final total = blob.sizeBytes;

    var start = 0;
    var end = total - 1;
    if (rangeHeader != null) {
      final match = _rangeHeader.firstMatch(rangeHeader.trim());
      if (match == null) throw const RangeNotSatisfiable();
      final rawStart = match.group(1)!;
      final rawEnd = match.group(2)!;
      if (rawStart.isEmpty && rawEnd.isEmpty) throw const RangeNotSatisfiable();
      if (rawStart.isEmpty) {
        // Suffix range: last N bytes.
        final suffix = int.parse(rawEnd);
        start = suffix >= total ? 0 : total - suffix;
      } else {
        start = int.parse(rawStart);
        if (rawEnd.isNotEmpty) end = int.parse(rawEnd).clamp(0, total - 1);
      }
      if (total == 0 || start > end || start >= total) {
        throw const RangeNotSatisfiable();
      }
    }
    return ContentRange(
      start: start,
      end: end,
      total: total,
      etag: blob.sha256,
      mimeType:
          document.snapshot['mime_type'] as String? ??
          'application/octet-stream',
      stream: total == 0
          ? const Stream.empty()
          : storage.read(key, start: start, end: end),
    );
  }
}

/// Maps to HTTP 416.
class RangeNotSatisfiable implements Exception {
  const RangeNotSatisfiable();
}
