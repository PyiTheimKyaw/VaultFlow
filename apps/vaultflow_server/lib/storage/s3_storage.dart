import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:vaultflow_server/config.dart';
import 'package:vaultflow_server/storage/storage_adapter.dart';

/// S3-compatible storage (MinIO in development).
///
/// Parts are stored as individual objects under `.uploads/<uploadId>/<n>`
/// and concatenated into the final object with a streaming `putObject` at
/// assembly time (the client library drives S3 multipart internally). That
/// doubles write traffic per upload but keeps every step idempotent and
/// only uses documented client calls.
class S3Storage implements StorageAdapter {
  S3Storage(this.config)
    : _minio = Minio(
        endPoint: config.endpoint,
        port: config.port,
        useSSL: config.useSsl,
        accessKey: config.accessKey,
        secretKey: config.secretKey,
        region: config.region,
      );

  final S3Config config;
  final Minio _minio;

  String get _bucket => config.bucket;

  String _partKey(String uploadId, int index) => '.uploads/$uploadId/$index';

  @override
  Future<void> putPart(String uploadId, int index, List<int> bytes) async {
    final data = Uint8List.fromList(bytes);
    await _minio.putObject(
      _bucket,
      _partKey(uploadId, index),
      Stream.value(data),
      size: data.length,
    );
  }

  @override
  Future<int> assemble(String uploadId, int count, String key) async {
    var size = 0;
    for (var i = 0; i < count; i++) {
      final stat = await _minio.statObject(_bucket, _partKey(uploadId, i));
      size += stat.size ?? 0;
    }
    Stream<Uint8List> concatenated() async* {
      for (var i = 0; i < count; i++) {
        final stream = await _minio.getObject(_bucket, _partKey(uploadId, i));
        await for (final chunk in stream) {
          yield Uint8List.fromList(chunk);
        }
      }
    }

    await _minio.putObject(_bucket, key, concatenated(), size: size);
    await abort(uploadId);
    return size;
  }

  @override
  Future<void> abort(String uploadId) async {
    final prefix = '.uploads/$uploadId/';
    await for (final result in _minio.listObjects(_bucket, prefix: prefix)) {
      for (final object in result.objects) {
        final name = object.key;
        if (name != null) await _minio.removeObject(_bucket, name);
      }
    }
  }

  @override
  Future<int?> sizeOf(String key) async {
    try {
      return (await _minio.statObject(_bucket, key)).size;
    } on MinioError {
      return null;
    }
  }

  @override
  Stream<List<int>> read(String key, {int? start, int? end}) async* {
    final length = start == null || end == null ? null : end - start + 1;
    final stream = await _minio.getPartialObject(_bucket, key, start, length);
    yield* stream;
  }

  @override
  Future<void> delete(String key) => _minio.removeObject(_bucket, key);
}
