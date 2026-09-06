import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/vf_protocol.dart';

part 'outbox_entry.freezed.dart';

/// Lifecycle of an outbox row.
enum OutboxState {
  /// Waiting to be pushed.
  pending,

  /// Currently inside a push request; never coalesced.
  inFlight,

  /// Gave up after repeated failures; surfaced to the user, never dropped.
  failed,

  /// Waiting on a transfer (document create before its upload completes).
  blocked,
}

/// One queued mutation, in FIFO order by [id].
@freezed
abstract class OutboxEntry with _$OutboxEntry {
  const factory OutboxEntry({
    required int id,
    required String clientOpId,
    required EntityType entityType,
    required String entityId,
    required SyncOp op,
    required Map<String, Object?> payload,
    required int baseVersion,
    required OutboxState state,
    required DateTime createdAt,
    String? dependsOnTransfer,
    @Default(0) int attemptCount,
    DateTime? nextAttemptAt,
    String? lastError,
  }) = _OutboxEntry;

  const OutboxEntry._();

  /// Converts to the wire shape used by `POST /sync/push`.
  SyncOpRequest toRequest() => SyncOpRequest(
    clientOpId: clientOpId,
    entityType: entityType,
    entityId: entityId,
    op: op,
    baseVersion: baseVersion,
    payload: payload,
  );
}
