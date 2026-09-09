import 'package:postgres/postgres.dart';
import 'package:vaultflow_server/transfer/models.dart';
import 'package:vaultflow_server/transfer/upload_store.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// [UploadStore] on Postgres (schema in `migrations/0003_uploads.sql`).
class PostgresUploadStore implements UploadStore {
  PostgresUploadStore(this._session);

  final Session _session;

  BlobRecord _blob(ResultRow r) {
    final m = r.toColumnMap();
    return BlobRecord(
      storageKey: m['storage_key'] as String,
      userId: m['user_id'] as String,
      sha256: m['sha256'] as String,
      sizeBytes: m['size_bytes'] as int,
      refCount: m['ref_count'] as int,
      createdAt: (m['created_at'] as DateTime).toUtc(),
    );
  }

  UploadSessionRecord _upload(ResultRow r) {
    final m = r.toColumnMap();
    final received = (m['received'] as Map).map(
      (k, v) => MapEntry(int.parse(k as String), v as String),
    );
    return UploadSessionRecord(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      documentId: m['document_id'] as String,
      storageKey: m['storage_key'] as String,
      mimeType: m['mime_type'] as String,
      totalBytes: m['total_bytes'] as int,
      chunkSize: m['chunk_size'] as int,
      sha256Expected: m['sha256_expected'] as String,
      received: received,
      state: UploadSessionState.values.byName(m['state'] as String),
      expiresAt: (m['expires_at'] as DateTime).toUtc(),
      createdAt: (m['created_at'] as DateTime).toUtc(),
    );
  }

  @override
  Future<BlobRecord?> findBlob(String userId, String sha256) async {
    final result = await _session.execute(
      Sql.named('SELECT * FROM blobs WHERE user_id = @user AND sha256 = @sha'),
      parameters: {'user': userId, 'sha': sha256},
    );
    return result.isEmpty ? null : _blob(result.first);
  }

  @override
  Future<BlobRecord?> findBlobByKey(String userId, String storageKey) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT * FROM blobs WHERE user_id = @user AND storage_key = @key',
      ),
      parameters: {'user': userId, 'key': storageKey},
    );
    return result.isEmpty ? null : _blob(result.first);
  }

  @override
  Future<void> insertBlob(BlobRecord blob) => _session.execute(
    Sql.named('''
      INSERT INTO blobs (storage_key, user_id, sha256, size_bytes, ref_count, created_at)
      VALUES (@key, @user, @sha, @size, @refs, @created)
      ON CONFLICT (storage_key) DO NOTHING'''),
    parameters: {
      'key': blob.storageKey,
      'user': blob.userId,
      'sha': blob.sha256,
      'size': blob.sizeBytes,
      'refs': blob.refCount,
      'created': blob.createdAt,
    },
  );

  @override
  Future<void> insertSession(UploadSessionRecord s) => _session.execute(
    Sql.named('''
      INSERT INTO upload_sessions
        (id, user_id, document_id, storage_key, mime_type, total_bytes,
         chunk_size, sha256_expected, received, state, expires_at, created_at)
      VALUES (@id, @user, @doc, @key, @mime, @total, @chunk, @sha,
              @received, @state, @expires, @created)'''),
    parameters: {
      'id': s.id,
      'user': s.userId,
      'doc': s.documentId,
      'key': s.storageKey,
      'mime': s.mimeType,
      'total': s.totalBytes,
      'chunk': s.chunkSize,
      'sha': s.sha256Expected,
      'received': TypedValue(
        Type.jsonb,
        s.received.map((k, v) => MapEntry('$k', v)),
      ),
      'state': s.state.name,
      'expires': s.expiresAt,
      'created': s.createdAt,
    },
  );

  @override
  Future<UploadSessionRecord?> findSession(String userId, String id) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT * FROM upload_sessions WHERE id = @id AND user_id = @user',
      ),
      parameters: {'id': id, 'user': userId},
    );
    return result.isEmpty ? null : _upload(result.first);
  }

  @override
  Future<UploadSessionRecord> markReceived(
    String id,
    int index,
    String sha256,
  ) async {
    final result = await _session.execute(
      Sql.named('''
        UPDATE upload_sessions
        SET received = received || jsonb_build_object(@idx::text, @sha::text)
        WHERE id = @id
        RETURNING *'''),
      parameters: {'id': id, 'idx': '$index', 'sha': sha256},
    );
    return _upload(result.first);
  }

  @override
  Future<void> setState(String id, UploadSessionState state) =>
      _session.execute(
        Sql.named('UPDATE upload_sessions SET state = @state WHERE id = @id'),
        parameters: {'state': state.name, 'id': id},
      );

  @override
  Future<List<UploadSessionRecord>> expiredSessions(DateTime now) async {
    final result = await _session.execute(
      Sql.named(
        "SELECT * FROM upload_sessions WHERE state = 'active' AND expires_at <= @now",
      ),
      parameters: {'now': now},
    );
    return result.map(_upload).toList();
  }

  @override
  Future<void> deleteSession(String id) => _session.execute(
    Sql.named('DELETE FROM upload_sessions WHERE id = @id'),
    parameters: {'id': id},
  );
}
