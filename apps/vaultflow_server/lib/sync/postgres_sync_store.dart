import 'package:postgres/postgres.dart';
import 'package:vaultflow_server/sync/sync_store.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// [SyncStore] on Postgres (schema in `migrations/0002_sync.sql`).
///
/// Snapshots are stored in typed columns and converted back to the wire
/// shape on read, so the database stays queryable while clients only ever
/// see DTO json.
class PostgresSyncStore implements SyncStore {
  PostgresSyncStore(this._session);

  final Session _session;

  @override
  Future<T> runInTransaction<T>(
    String userId,
    Future<T> Function(SyncStore tx) body,
  ) {
    final session = _session;
    if (session is Pool) {
      return session.runTx((tx) async {
        // Serialise this user's ops: concurrent pushes from two devices
        // must not both read the same version and both be applied.
        await tx.execute(
          Sql.named('SELECT pg_advisory_xact_lock(hashtext(@user))'),
          parameters: {'user': userId},
        );
        return await body(PostgresSyncStore(tx));
      });
    }
    return body(this);
  }

  static String _table(EntityType type) => switch (type) {
    EntityType.folder => 'folders',
    EntityType.document => 'documents',
    EntityType.note => 'notes',
  };

  @override
  Future<StoredEntity?> find(String userId, EntityType type, String id) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT * FROM ${_table(type)} WHERE user_id = @user AND id = @id',
      ),
      parameters: {'user': userId, 'id': id},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return StoredEntity(
      type: type,
      id: id,
      version: row['version'] as int,
      snapshot: _snapshot(type, row),
    );
  }

  static Map<String, Object?> _snapshot(
    EntityType type,
    Map<String, Object?> r,
  ) {
    String? iso(Object? v) =>
        v == null ? null : (v as DateTime).toUtc().toIso8601String();
    final common = <String, Object?>{
      'id': r['id'],
      'version': r['version'],
      'created_at': iso(r['created_at']),
      'updated_at': iso(r['updated_at']),
      if (r['deleted_at'] != null) 'deleted_at': iso(r['deleted_at']),
    };
    return switch (type) {
      EntityType.folder => {
        ...common,
        'name': r['name'],
        if (r['parent_id'] != null) 'parent_id': r['parent_id'],
      },
      EntityType.document => {
        ...common,
        'name': r['name'],
        'mime_type': r['mime_type'],
        'size_bytes': r['size_bytes'],
        'sha256': r['sha256'],
        if (r['folder_id'] != null) 'folder_id': r['folder_id'],
        if (r['storage_key'] != null) 'storage_key': r['storage_key'],
      },
      EntityType.note => {
        ...common,
        'title': r['title'],
        'body': r['body'],
        if (r['folder_id'] != null) 'folder_id': r['folder_id'],
      },
    };
  }

  @override
  Future<void> upsert(String userId, StoredEntity entity) {
    final s = entity.snapshot;
    DateTime? ts(String key) =>
        s[key] == null ? null : DateTime.parse(s[key]! as String);
    final base = {
      'id': entity.id,
      'user': userId,
      'version': entity.version,
      'created': ts('created_at'),
      'updated': ts('updated_at'),
      'deleted': ts('deleted_at'),
    };
    return switch (entity.type) {
      EntityType.folder => _session.execute(
        Sql.named('''
          INSERT INTO folders
            (id, user_id, parent_id, name, version, created_at, updated_at, deleted_at)
          VALUES (@id, @user, @parent, @name, @version, @created, @updated, @deleted)
          ON CONFLICT (id) DO UPDATE SET
            parent_id = EXCLUDED.parent_id, name = EXCLUDED.name,
            version = EXCLUDED.version, updated_at = EXCLUDED.updated_at,
            deleted_at = EXCLUDED.deleted_at'''),
        parameters: {...base, 'parent': s['parent_id'], 'name': s['name']},
      ),
      EntityType.document => _session.execute(
        Sql.named('''
          INSERT INTO documents
            (id, user_id, folder_id, name, mime_type, size_bytes, sha256,
             storage_key, version, created_at, updated_at, deleted_at)
          VALUES (@id, @user, @folder, @name, @mime, @size, @sha, @key,
                  @version, @created, @updated, @deleted)
          ON CONFLICT (id) DO UPDATE SET
            folder_id = EXCLUDED.folder_id, name = EXCLUDED.name,
            mime_type = EXCLUDED.mime_type, size_bytes = EXCLUDED.size_bytes,
            sha256 = EXCLUDED.sha256, storage_key = EXCLUDED.storage_key,
            version = EXCLUDED.version, updated_at = EXCLUDED.updated_at,
            deleted_at = EXCLUDED.deleted_at'''),
        parameters: {
          ...base,
          'folder': s['folder_id'],
          'name': s['name'],
          'mime': s['mime_type'],
          'size': s['size_bytes'],
          'sha': s['sha256'],
          'key': s['storage_key'],
        },
      ),
      EntityType.note => _session.execute(
        Sql.named(
          '''
          INSERT INTO notes
            (id, user_id, folder_id, title, body, version, created_at, updated_at, deleted_at)
          VALUES (@id, @user, @folder, @title, @body, @version, @created, @updated, @deleted)
          ON CONFLICT (id) DO UPDATE SET
            folder_id = EXCLUDED.folder_id, title = EXCLUDED.title,
            body = EXCLUDED.body, version = EXCLUDED.version,
            updated_at = EXCLUDED.updated_at, deleted_at = EXCLUDED.deleted_at''',
        ),
        parameters: {
          ...base,
          'folder': s['folder_id'],
          'title': s['title'],
          'body': s['body'],
        },
      ),
    };
  }

  @override
  Future<int> appendChange({
    required String userId,
    required String deviceId,
    required EntityType entityType,
    required String entityId,
    required SyncOp op,
    required int version,
    required Map<String, Object?> payload,
    required DateTime createdAt,
  }) async {
    final result = await _session.execute(
      Sql.named('''
        INSERT INTO changes
          (user_id, device_id, entity_type, entity_id, op, version, payload, created_at)
        VALUES (@user, @device, @type, @entity, @op, @version, @payload, @created)
        RETURNING seq'''),
      parameters: {
        'user': userId,
        'device': deviceId,
        'type': entityType.name,
        'entity': entityId,
        'op': op.name,
        'version': version,
        'payload': TypedValue(Type.jsonb, payload),
        'created': createdAt,
      },
    );
    return result.first[0]! as int;
  }

  @override
  Future<List<ChangeRecord>> changesSince(
    String userId, {
    required int since,
    required int limit,
    String? excludeDeviceId,
  }) async {
    final result = await _session.execute(
      Sql.named('''
        SELECT * FROM changes
        WHERE user_id = @user AND seq > @since
          AND (@device::text IS NULL OR device_id <> @device)
        ORDER BY seq
        LIMIT @limit'''),
      parameters: {
        'user': userId,
        'since': since,
        'device': excludeDeviceId,
        'limit': limit,
      },
    );
    return result.map((r) => _record(r.toColumnMap())).toList();
  }

  @override
  Future<ChangeRecord?> latestChange(String userId) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT * FROM changes WHERE user_id = @user '
        'ORDER BY seq DESC LIMIT 1',
      ),
      parameters: {'user': userId},
    );
    if (result.isEmpty) return null;
    return _record(result.first.toColumnMap());
  }

  static ChangeRecord _record(Map<String, dynamic> m) {
    return ChangeRecord(
      seq: m['seq'] as int,
      userId: m['user_id'] as String,
      deviceId: m['device_id'] as String,
      entityType: EntityType.fromWire(m['entity_type'] as String),
      entityId: m['entity_id'] as String,
      op: SyncOp.fromWire(m['op'] as String),
      version: m['version'] as int,
      payload: (m['payload'] as Map).cast<String, Object?>(),
      createdAt: (m['created_at'] as DateTime).toUtc(),
    );
  }

  @override
  Future<Map<String, Object?>?> findAppliedOp(
    String deviceId,
    String clientOpId,
  ) async {
    final result = await _session.execute(
      Sql.named(
        'SELECT result FROM applied_ops '
        'WHERE device_id = @device AND client_op_id = @op',
      ),
      parameters: {'device': deviceId, 'op': clientOpId},
    );
    if (result.isEmpty) return null;
    return (result.first[0]! as Map).cast<String, Object?>();
  }

  @override
  Future<void> recordAppliedOp(
    String deviceId,
    String clientOpId,
    Map<String, Object?> result,
  ) => _session.execute(
    Sql.named(
      'INSERT INTO applied_ops (device_id, client_op_id, result) '
      'VALUES (@device, @op, @result) ON CONFLICT DO NOTHING',
    ),
    parameters: {
      'device': deviceId,
      'op': clientOpId,
      'result': TypedValue(Type.jsonb, result),
    },
  );
}
