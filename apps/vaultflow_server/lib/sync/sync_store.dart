import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Current server copy of one entity.
@immutable
class StoredEntity {
  const StoredEntity({
    required this.type,
    required this.id,
    required this.version,
    required this.snapshot,
  });

  final EntityType type;
  final String id;
  final int version;

  /// Wire-shaped snapshot (`FolderDto` / `DocumentDto` / `NoteDto` json),
  /// including `version` and `deleted_at`.
  final Map<String, Object?> snapshot;

  bool get isDeleted => snapshot['deleted_at'] != null;
}

/// One row of the change feed.
@immutable
class ChangeRecord {
  const ChangeRecord({
    required this.seq,
    required this.userId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.version,
    required this.payload,
    required this.createdAt,
  });

  final int seq;
  final String userId;
  final String deviceId;
  final EntityType entityType;
  final String entityId;
  final SyncOp op;
  final int version;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  ChangeDto toDto() => ChangeDto(
    seq: seq,
    entityType: entityType,
    entityId: entityId,
    op: op,
    version: version,
    deviceId: deviceId,
    createdAt: createdAt,
    payload: payload,
  );
}

/// Persistence for synced entities, the change feed and applied ops.
///
/// [runInTransaction] hands the body a store bound to one transaction; every
/// op in a push is applied through it so the version check, the write and
/// the change-feed append are atomic. Transactions for the same user
/// are serialised, otherwise two devices pushing at the same instant could
/// both read the old version and both be applied.
abstract interface class SyncStore {
  Future<T> runInTransaction<T>(
    String userId,
    Future<T> Function(SyncStore tx) body,
  );

  Future<StoredEntity?> find(String userId, EntityType type, String id);

  Future<void> upsert(String userId, StoredEntity entity);

  /// Appends to the feed and returns the new sequence number.
  Future<int> appendChange({
    required String userId,
    required String deviceId,
    required EntityType entityType,
    required String entityId,
    required SyncOp op,
    required int version,
    required Map<String, Object?> payload,
    required DateTime createdAt,
  });

  Future<List<ChangeRecord>> changesSince(
    String userId, {
    required int since,
    required int limit,
    String? excludeDeviceId,
  });

  Future<Map<String, Object?>?> findAppliedOp(
    String deviceId,
    String clientOpId,
  );

  Future<void> recordAppliedOp(
    String deviceId,
    String clientOpId,
    Map<String, Object?> result,
  );
}

/// Map-backed [SyncStore] for tests and `dart_frog dev` without Postgres.
class InMemorySyncStore implements SyncStore {
  final Map<String, StoredEntity> entities = {};
  final List<ChangeRecord> changes = [];
  final Map<String, Map<String, Object?>> appliedOps = {};

  static String _key(String userId, EntityType type, String id) =>
      '$userId/${type.name}/$id';

  final Map<String, Completer<void>> _locks = {};

  @override
  Future<T> runInTransaction<T>(
    String userId,
    Future<T> Function(SyncStore tx) body,
  ) async {
    // Per-user mutex: wait for the transaction currently registered for this
    // user, then register ours so the next caller waits for us. Bodies for
    // one user therefore never interleave at their await points.
    final previous = _locks[userId]?.future ?? Future<void>.value();
    final completer = Completer<void>();
    _locks[userId] = completer;
    await previous;
    try {
      return await body(this);
    } finally {
      completer.complete();
      // Only drop the entry if no later transaction has replaced it.
      if (identical(_locks[userId], completer)) _locks.remove(userId);
    }
  }

  @override
  Future<StoredEntity?> find(String userId, EntityType type, String id) async =>
      entities[_key(userId, type, id)];

  @override
  Future<void> upsert(String userId, StoredEntity entity) async =>
      entities[_key(userId, entity.type, entity.id)] = entity;

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
    final seq = changes.length + 1;
    changes.add(
      ChangeRecord(
        seq: seq,
        userId: userId,
        deviceId: deviceId,
        entityType: entityType,
        entityId: entityId,
        op: op,
        version: version,
        payload: payload,
        createdAt: createdAt,
      ),
    );
    return seq;
  }

  @override
  Future<List<ChangeRecord>> changesSince(
    String userId, {
    required int since,
    required int limit,
    String? excludeDeviceId,
  }) async => changes
      .where(
        (c) =>
            c.userId == userId &&
            c.seq > since &&
            (excludeDeviceId == null || c.deviceId != excludeDeviceId),
      )
      .take(limit)
      .toList();

  @override
  Future<Map<String, Object?>?> findAppliedOp(
    String deviceId,
    String clientOpId,
  ) async => appliedOps['$deviceId/$clientOpId'];

  @override
  Future<void> recordAppliedOp(
    String deviceId,
    String clientOpId,
    Map<String, Object?> result,
  ) async => appliedOps['$deviceId/$clientOpId'] = result;
}
