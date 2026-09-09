import 'package:meta/meta.dart';
import 'package:vf_protocol/vf_protocol.dart';

@immutable
class BlobRecord {
  const BlobRecord({
    required this.storageKey,
    required this.userId,
    required this.sha256,
    required this.sizeBytes,
    required this.createdAt,
    this.refCount = 1,
  });

  final String storageKey;
  final String userId;
  final String sha256;
  final int sizeBytes;
  final int refCount;
  final DateTime createdAt;
}

@immutable
class UploadSessionRecord {
  const UploadSessionRecord({
    required this.id,
    required this.userId,
    required this.documentId,
    required this.storageKey,
    required this.mimeType,
    required this.totalBytes,
    required this.chunkSize,
    required this.sha256Expected,
    required this.expiresAt,
    required this.createdAt,
    this.received = const {},
    this.state = UploadSessionState.active,
  });

  final String id;
  final String userId;
  final String documentId;
  final String storageKey;
  final String mimeType;
  final int totalBytes;
  final int chunkSize;
  final String sha256Expected;

  /// Chunk index → sha256 of that chunk, for every part received so far.
  final Map<int, String> received;
  final UploadSessionState state;
  final DateTime expiresAt;
  final DateTime createdAt;

  int get chunkCount =>
      totalBytes == 0 ? 1 : (totalBytes + chunkSize - 1) ~/ chunkSize;

  int chunkLength(int index) {
    if (totalBytes == 0) return 0;
    final last = chunkCount - 1;
    return index < last ? chunkSize : totalBytes - last * chunkSize;
  }

  bool get isComplete => received.length == chunkCount;

  UploadSessionRecord copyWith({
    Map<int, String>? received,
    UploadSessionState? state,
  }) => UploadSessionRecord(
    id: id,
    userId: userId,
    documentId: documentId,
    storageKey: storageKey,
    mimeType: mimeType,
    totalBytes: totalBytes,
    chunkSize: chunkSize,
    sha256Expected: sha256Expected,
    expiresAt: expiresAt,
    createdAt: createdAt,
    received: received ?? this.received,
    state: state ?? this.state,
  );
}
