import 'package:crypto/crypto.dart';
import 'package:vf_transfer/src/hasher_stub.dart'
    if (dart.library.io) 'package:vf_transfer/src/hasher_io.dart'
    as impl;

/// SHA-256 helpers. File hashing runs in a separate isolate on native so a
/// multi-gigabyte verify never blocks the UI thread.
abstract final class Hasher {
  static String ofBytes(List<int> bytes) => sha256.convert(bytes).toString();

  static Future<String> ofFile(String path) => impl.hashFile(path);

  /// Hashes a byte stream incrementally.
  static Future<String> ofStream(Stream<List<int>> stream) async =>
      (await sha256.bind(stream).first).toString();
}
