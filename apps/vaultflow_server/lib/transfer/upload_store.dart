import 'package:vaultflow_server/transfer/models.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Persistence for blobs and upload sessions.
abstract interface class UploadStore {
  Future<BlobRecord?> findBlob(String userId, String sha256);

  Future<BlobRecord?> findBlobByKey(String userId, String storageKey);

  Future<void> insertBlob(BlobRecord blob);

  Future<void> insertSession(UploadSessionRecord session);

  Future<UploadSessionRecord?> findSession(String userId, String id);

  /// Records one received part; returns the updated session.
  Future<UploadSessionRecord> markReceived(String id, int index, String sha256);

  Future<void> setState(String id, UploadSessionState state);

  /// Sessions past their expiry that are still active.
  Future<List<UploadSessionRecord>> expiredSessions(DateTime now);

  Future<void> deleteSession(String id);
}

/// Map-backed [UploadStore] for tests and for `dart_frog dev` without
/// Postgres.
class InMemoryUploadStore implements UploadStore {
  final Map<String, BlobRecord> blobs = {};
  final Map<String, UploadSessionRecord> sessions = {};

  @override
  Future<BlobRecord?> findBlob(String userId, String sha256) async => blobs
      .values
      .where((b) => b.userId == userId && b.sha256 == sha256)
      .firstOrNull;

  @override
  Future<BlobRecord?> findBlobByKey(String userId, String storageKey) async {
    final blob = blobs[storageKey];
    return blob != null && blob.userId == userId ? blob : null;
  }

  @override
  Future<void> insertBlob(BlobRecord blob) async =>
      blobs.putIfAbsent(blob.storageKey, () => blob);

  @override
  Future<void> insertSession(UploadSessionRecord session) async =>
      sessions[session.id] = session;

  @override
  Future<UploadSessionRecord?> findSession(String userId, String id) async {
    final session = sessions[id];
    return session != null && session.userId == userId ? session : null;
  }

  @override
  Future<UploadSessionRecord> markReceived(
    String id,
    int index,
    String sha256,
  ) async {
    final session = sessions[id]!;
    final updated = session.copyWith(
      received: {...session.received, index: sha256},
    );
    sessions[id] = updated;
    return updated;
  }

  @override
  Future<void> setState(String id, UploadSessionState state) async {
    final session = sessions[id];
    if (session != null) sessions[id] = session.copyWith(state: state);
  }

  @override
  Future<List<UploadSessionRecord>> expiredSessions(DateTime now) async =>
      sessions.values
          .where(
            (s) =>
                s.state == UploadSessionState.active &&
                !s.expiresAt.isAfter(now),
          )
          .toList();

  @override
  Future<void> deleteSession(String id) async => sessions.remove(id);
}
