import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/storage/storage_adapter.dart';
import 'package:vaultflow_server/sync/sync_store.dart';
import 'package:vaultflow_server/transfer/models.dart';
import 'package:vaultflow_server/transfer/upload_store.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

const _log = Logger('uploads');

/// Resumable chunked uploads with content-addressed dedupe.
///
/// A blob is keyed by `(user, sha256)`. Creating a session for a hash the
/// user already stored returns `dedup: true` and no bytes travel. Otherwise
/// chunks are accepted in any order and idempotently; `complete` assembles
/// them, verifies size and hash, registers the blob and, if the document
/// already exists on the server, stamps its `storage_key`.
class UploadService {
  UploadService({
    required this.store,
    required this.storage,
    required this.sync,
    this.sessionTtl = const Duration(hours: 24),
    this.maxChunkSize = 8 * 1024 * 1024,
    this.clock = const SystemClock(),
  });

  final UploadStore store;
  final StorageAdapter storage;
  final SyncStore sync;
  final Duration sessionTtl;
  final int maxChunkSize;
  final Clock clock;

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// Content-addressed object key; identical files share one object.
  static String storageKeyFor(String userId, String sha256) =>
      'u/$userId/${sha256.substring(0, 2)}/$sha256';

  Future<UploadSessionResponse> create(
    String userId,
    UploadSessionCreateRequest request,
  ) async {
    if (!VfId.isValid(request.documentId)) {
      throw const ApiException.validation('document_id must be a UUID');
    }
    if (!_hex64.hasMatch(request.sha256)) {
      throw const ApiException.validation('sha256 must be 64 hex characters');
    }
    if (request.totalBytes < 0) {
      throw const ApiException.validation('total_bytes must be >= 0');
    }
    if (request.chunkSize <= 0 || request.chunkSize > maxChunkSize) {
      throw ApiException.validation('chunk_size must be 1..$maxChunkSize');
    }
    await gcExpired();

    final existing = await store.findBlob(userId, request.sha256);
    if (existing != null) {
      _log.info(
        'dedup hit',
        fields: {'user': userId, 'sha256': request.sha256},
      );
      return UploadSessionResponse(
        dedup: true,
        storageKey: existing.storageKey,
      );
    }

    final now = clock.now();
    final session = UploadSessionRecord(
      id: VfId.next(),
      userId: userId,
      documentId: request.documentId,
      storageKey: storageKeyFor(userId, request.sha256),
      mimeType: request.mimeType,
      totalBytes: request.totalBytes,
      chunkSize: request.chunkSize,
      sha256Expected: request.sha256,
      expiresAt: now.add(sessionTtl),
      createdAt: now,
    );
    await store.insertSession(session);
    return UploadSessionResponse(
      uploadId: session.id,
      chunkSize: session.chunkSize,
      expiresAt: session.expiresAt,
    );
  }

  Future<UploadSessionStatus> status(String userId, String id) async {
    final session = await _active(userId, id);
    return UploadSessionStatus(
      uploadId: session.id,
      state: session.state,
      totalBytes: session.totalBytes,
      chunkSize: session.chunkSize,
      receivedChunks: session.received.keys.toList()..sort(),
      expiresAt: session.expiresAt,
    );
  }

  Future<UploadChunkResponse> putChunk(
    String userId,
    String id,
    int index,
    List<int> bytes, {
    String? declaredSha256,
  }) async {
    final session = await _active(userId, id);
    if (index < 0 || index >= session.chunkCount) {
      throw ApiException.validation(
        'chunk index out of range (0..${session.chunkCount - 1})',
      );
    }
    final expectedLength = session.chunkLength(index);
    if (bytes.length != expectedLength) {
      throw ApiException(
        ApiErrorCode.chunkMismatch,
        'chunk $index must be $expectedLength bytes, got ${bytes.length}',
      );
    }
    final actualSha = sha256.convert(bytes).toString();
    if (declaredSha256 != null && declaredSha256 != actualSha) {
      throw const ApiException(
        ApiErrorCode.chunkMismatch,
        'chunk body does not match X-Chunk-Sha256',
      );
    }
    final already = session.received[index];
    if (already == actualSha) {
      return UploadChunkResponse(
        index: index,
        receivedCount: session.received.length,
        etag: actualSha,
      );
    }
    await storage.putPart(session.id, index, bytes);
    final updated = await store.markReceived(session.id, index, actualSha);
    return UploadChunkResponse(
      index: index,
      receivedCount: updated.received.length,
      etag: actualSha,
    );
  }

  Future<UploadCompleteResponse> complete(
    String userId,
    String deviceId,
    String id,
  ) async {
    final session = await _active(userId, id);
    if (!session.isComplete) {
      final missing = [
        for (var i = 0; i < session.chunkCount; i++)
          if (!session.received.containsKey(i)) i,
      ];
      throw ApiException(
        ApiErrorCode.chunkMismatch,
        'upload incomplete; missing chunks ${missing.take(10).toList()}',
        details: {'missing': missing},
      );
    }

    // Another session for the same content may have finished first.
    final existingBlob = await store.findBlob(userId, session.sha256Expected);
    if (existingBlob == null) {
      final size = await storage.assemble(
        session.id,
        session.chunkCount,
        session.storageKey,
      );
      if (size != session.totalBytes) {
        await storage.delete(session.storageKey);
        await store.setState(session.id, UploadSessionState.aborted);
        throw ApiException(
          ApiErrorCode.hashMismatch,
          'assembled size $size != declared ${session.totalBytes}',
        );
      }
      final digest = await sha256.bind(storage.read(session.storageKey)).first;
      if (digest.toString() != session.sha256Expected) {
        await storage.delete(session.storageKey);
        await store.setState(session.id, UploadSessionState.aborted);
        throw const ApiException(
          ApiErrorCode.hashMismatch,
          'uploaded content does not match the declared sha256',
        );
      }
      await store.insertBlob(
        BlobRecord(
          storageKey: session.storageKey,
          userId: userId,
          sha256: session.sha256Expected,
          sizeBytes: size,
          createdAt: clock.now(),
        ),
      );
    } else {
      await storage.abort(session.id);
    }
    await store.setState(session.id, UploadSessionState.completed);

    final version = await _stampDocument(
      userId: userId,
      deviceId: deviceId,
      documentId: session.documentId,
      storageKey: session.storageKey,
    );
    return UploadCompleteResponse(
      documentId: session.documentId,
      version: version,
      storageKey: session.storageKey,
    );
  }

  /// Sets `storage_key` on the server copy of the document when it exists.
  /// A document whose create is still queued client-side is left alone; the
  /// client includes the key in that create.
  Future<int> _stampDocument({
    required String userId,
    required String deviceId,
    required String documentId,
    required String storageKey,
  }) => sync.runInTransaction(userId, (tx) async {
    final current = await tx.find(userId, EntityType.document, documentId);
    if (current == null) return 0;
    if (current.snapshot['storage_key'] == storageKey) return current.version;
    final next = Map<String, Object?>.of(current.snapshot)
      ..['storage_key'] = storageKey
      ..['updated_at'] = clock.now().toIso8601String();
    final version = current.version + 1;
    next['version'] = version;
    await tx.upsert(
      userId,
      StoredEntity(
        type: EntityType.document,
        id: documentId,
        version: version,
        snapshot: next,
      ),
    );
    await tx.appendChange(
      userId: userId,
      deviceId: deviceId,
      entityType: EntityType.document,
      entityId: documentId,
      op: SyncOp.update,
      version: version,
      payload: next,
      createdAt: clock.now(),
    );
    return version;
  });

  /// Drops sessions past their expiry along with their parts.
  Future<int> gcExpired() async {
    final expired = await store.expiredSessions(clock.now());
    for (final session in expired) {
      await storage.abort(session.id);
      await store.deleteSession(session.id);
    }
    if (expired.isNotEmpty) {
      _log.info(
        'expired upload sessions removed',
        fields: {'count': expired.length},
      );
    }
    return expired.length;
  }

  Future<UploadSessionRecord> _active(String userId, String id) async {
    final session = await store.findSession(userId, id);
    if (session == null || session.state == UploadSessionState.aborted) {
      throw const ApiException.notFound('Upload session not found');
    }
    if (session.state == UploadSessionState.completed) {
      throw const ApiException(
        ApiErrorCode.conflict,
        'Upload session already completed',
      );
    }
    if (!session.expiresAt.isAfter(clock.now())) {
      await storage.abort(session.id);
      await store.deleteSession(session.id);
      throw const ApiException(
        ApiErrorCode.uploadExpired,
        'Upload session expired; start a new one',
      );
    }
    return session;
  }

  /// Whether [storageKey] names a blob owned by [userId]; used by the sync
  /// service to validate document snapshots.
  Future<bool> ownsBlob(String userId, String storageKey) async =>
      await store.findBlobByKey(userId, storageKey) != null;

  /// Debug helper for tests.
  static String hashOf(List<int> bytes) => sha256.convert(bytes).toString();

  static String hashOfString(String text) => hashOf(utf8.encode(text));
}
