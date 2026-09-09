import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/sync/sync_store.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Applies pushed ops with optimistic versioning and serves the change feed.
///
/// Rules per op (inside one transaction):
/// 1. A `(device_id, client_op_id)` seen before returns the stored result.
/// 2. Missing entity and op is not create → `rejected`.
/// 3. `current.version != base_version` → `conflict` with the server
///    snapshot; the op is not applied.
/// 4. Otherwise apply, bump the version, append to the change feed.
class SyncService {
  SyncService({
    required this.store,
    this.clock = const SystemClock(),
    this.ownsBlob,
  });

  final SyncStore store;
  final Clock clock;

  /// Whether `(userId, storageKey)` names a blob the user uploaded; when
  /// set, document snapshots with a foreign `storage_key` are rejected.
  final Future<bool> Function(String userId, String storageKey)? ownsBlob;

  Future<PushResponse> push({
    required String userId,
    required String deviceId,
    required PushRequest request,
  }) async {
    if (request.ops.length > vfMaxPushOps) {
      throw const ApiException.validation('At most $vfMaxPushOps ops per push');
    }
    final results = <SyncOpResult>[];
    for (final op in request.ops) {
      results.add(
        await store.runInTransaction(
          userId,
          (tx) => _applyOne(tx, userId: userId, deviceId: deviceId, op: op),
        ),
      );
    }
    return PushResponse(results: results);
  }

  Future<ChangesResponse> changes({
    required String userId,
    required int since,
    required int limit,
    String? excludeDeviceId,
  }) async {
    final pageSize = limit.clamp(1, vfMaxChangesPageSize);
    // Fetch one extra row to learn whether more pages exist.
    final rows = await store.changesSince(
      userId,
      since: since,
      limit: pageSize + 1,
      excludeDeviceId: excludeDeviceId,
    );
    final hasMore = rows.length > pageSize;
    final page = hasMore ? rows.sublist(0, pageSize) : rows;
    return ChangesResponse(
      changes: page.map((c) => c.toDto()).toList(),
      nextCursor: page.isEmpty ? since : page.last.seq,
      hasMore: hasMore,
    );
  }

  Future<SyncOpResult> _applyOne(
    SyncStore tx, {
    required String userId,
    required String deviceId,
    required SyncOpRequest op,
  }) async {
    final replay = await tx.findAppliedOp(deviceId, op.clientOpId);
    if (replay != null) return SyncOpResult.fromJson(replay);

    final result = await _evaluate(
      tx,
      userId: userId,
      deviceId: deviceId,
      op: op,
    );
    await tx.recordAppliedOp(deviceId, op.clientOpId, result.toJson());
    return result;
  }

  Future<SyncOpResult> _evaluate(
    SyncStore tx, {
    required String userId,
    required String deviceId,
    required SyncOpRequest op,
  }) async {
    if (!VfId.isValid(op.entityId)) {
      return _rejected(op, 'entity_id must be a UUID');
    }
    final current = await tx.find(userId, op.entityType, op.entityId);

    if (current == null && op.op != SyncOp.create) {
      return _rejected(op, 'entity does not exist on the server');
    }
    final currentVersion = current?.version ?? 0;
    if (currentVersion != op.baseVersion) {
      return SyncOpResult(
        clientOpId: op.clientOpId,
        status: SyncOpStatus.conflict,
        remote: current?.snapshot ?? const {},
        remoteVersion: currentVersion,
      );
    }

    final Map<String, Object?> next;
    try {
      next = _nextSnapshot(op, current);
    } on FormatException catch (e) {
      return _rejected(op, e.message);
    } on Object catch (e) {
      return _rejected(op, 'invalid payload: $e');
    }
    if (op.entityType == EntityType.document) {
      final key = next['storage_key'];
      final check = ownsBlob;
      if (key is String && check != null && !await check(userId, key)) {
        return _rejected(op, 'storage_key does not name a blob you uploaded');
      }
    }
    final newVersion = currentVersion + 1;
    next['version'] = newVersion;
    next['id'] = op.entityId;

    await tx.upsert(
      userId,
      StoredEntity(
        type: op.entityType,
        id: op.entityId,
        version: newVersion,
        snapshot: next,
      ),
    );
    await tx.appendChange(
      userId: userId,
      deviceId: deviceId,
      entityType: op.entityType,
      entityId: op.entityId,
      op: op.op,
      version: newVersion,
      payload: next,
      createdAt: clock.now(),
    );
    return SyncOpResult(
      clientOpId: op.clientOpId,
      status: SyncOpStatus.applied,
      newVersion: newVersion,
    );
  }

  /// Computes the snapshot after [op]. Create/update carry a full snapshot
  /// (validated by parsing it as the DTO); move carries only the parent;
  /// delete tombstones the current snapshot.
  Map<String, Object?> _nextSnapshot(SyncOpRequest op, StoredEntity? current) {
    final now = clock.now().toIso8601String();
    switch (op.op) {
      case SyncOp.create:
      case SyncOp.update:
        final snapshot = Map<String, Object?>.of(op.payload)
          ..['id'] = op.entityId;
        _validate(op.entityType, snapshot);
        if (current != null) {
          // The server owns creation time.
          snapshot['created_at'] = current.snapshot['created_at'];
        }
        snapshot['updated_at'] ??= now;
        snapshot['created_at'] ??= snapshot['updated_at'];
        return snapshot;
      case SyncOp.move:
        final parentKey = op.entityType == EntityType.folder
            ? 'parent_id'
            : 'folder_id';
        if (!op.payload.containsKey(parentKey)) {
          throw FormatException('move payload must contain $parentKey');
        }
        final target = op.payload[parentKey];
        if (target != null && target is! String) {
          throw FormatException('$parentKey must be a string or null');
        }
        return Map<String, Object?>.of(current!.snapshot)
          ..[parentKey] = target
          ..['updated_at'] = now;
      case SyncOp.delete:
        return Map<String, Object?>.of(current!.snapshot)
          ..['deleted_at'] = now
          ..['updated_at'] = now;
    }
  }

  static void _validate(EntityType type, Map<String, Object?> snapshot) {
    // Parsing through the DTO is the schema check; version is filled by us.
    final withVersion = {...snapshot, 'version': 0};
    withVersion['created_at'] ??= DateTime.utc(2000).toIso8601String();
    withVersion['updated_at'] ??= withVersion['created_at'];
    switch (type) {
      case EntityType.folder:
        FolderDto.fromJson(withVersion);
      case EntityType.document:
        DocumentDto.fromJson(withVersion);
      case EntityType.note:
        NoteDto.fromJson(withVersion);
    }
  }

  static SyncOpResult _rejected(SyncOpRequest op, String reason) =>
      SyncOpResult(
        clientOpId: op.clientOpId,
        status: SyncOpStatus.rejected,
        error: reason,
      );
}
