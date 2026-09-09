import 'dart:io';

import 'package:path/path.dart' as p;

/// Where document bytes live. Uploads arrive as independent parts that are
/// assembled once every part is present; reads are ranged.
abstract interface class StorageAdapter {
  /// Stores one part of an in-progress upload; idempotent per index.
  Future<void> putPart(String uploadId, int index, List<int> bytes);

  /// Assembles parts `0..count-1` into the object at [key] and removes the
  /// parts. Returns the final object size.
  Future<int> assemble(String uploadId, int count, String key);

  /// Drops any parts of an abandoned upload.
  Future<void> abort(String uploadId);

  Future<int?> sizeOf(String key);

  /// Bytes `[start, end]` inclusive of the object (whole object when both
  /// are null).
  Stream<List<int>> read(String key, {int? start, int? end});

  Future<void> delete(String key);
}

/// Files on disk: parts under `<root>/.uploads/<uploadId>/<index>`, objects
/// under `<root>/<key>`.
class LocalFsStorage implements StorageAdapter {
  LocalFsStorage(this.root);

  final String root;

  Directory _partsDir(String uploadId) =>
      Directory(p.join(root, '.uploads', _safe(uploadId)));

  File _object(String key) => File(p.join(root, _safeKey(key)));

  @override
  Future<void> putPart(String uploadId, int index, List<int> bytes) async {
    final dir = _partsDir(uploadId);
    await dir.create(recursive: true);
    final tmp = File(p.join(dir.path, '$index.tmp'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(dir.path, '$index'));
  }

  @override
  Future<int> assemble(String uploadId, int count, String key) async {
    final dir = _partsDir(uploadId);
    final target = _object(key);
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.assembling');
    final sink = tmp.openWrite();
    var size = 0;
    try {
      for (var i = 0; i < count; i++) {
        final part = File(p.join(dir.path, '$i'));
        if (!part.existsSync()) {
          throw StateError('missing part $i of upload $uploadId');
        }
        await sink.addStream(part.openRead());
        size += await part.length();
      }
    } finally {
      await sink.close();
    }
    await tmp.rename(target.path);
    await abort(uploadId);
    return size;
  }

  @override
  Future<void> abort(String uploadId) async {
    final dir = _partsDir(uploadId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<int?> sizeOf(String key) async {
    final file = _object(key);
    return file.existsSync() ? await file.length() : null;
  }

  @override
  Stream<List<int>> read(String key, {int? start, int? end}) =>
      _object(key).openRead(start, end == null ? null : end + 1);

  @override
  Future<void> delete(String key) async {
    final file = _object(key);
    if (file.existsSync()) await file.delete();
  }

  static String _safe(String id) =>
      id.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');

  /// Keys are `<segment>/<segment>/...`; each segment is sanitised so a key
  /// can never escape [root].
  static String _safeKey(String key) =>
      key.split('/').where((s) => s.isNotEmpty).map(_safe).join(p.separator);
}
