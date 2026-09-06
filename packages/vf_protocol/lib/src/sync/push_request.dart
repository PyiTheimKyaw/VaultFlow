import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/src/enums/entity_type.dart';
import 'package:vf_protocol/src/enums/sync_op.dart';

part 'push_request.freezed.dart';
part 'push_request.g.dart';

/// One outbox entry as sent to the server.
@freezed
abstract class SyncOpRequest with _$SyncOpRequest {
  const factory SyncOpRequest({
    /// Idempotency key; the server stores the result per `(device, op id)`.
    required String clientOpId,
    required EntityType entityType,
    required String entityId,
    required SyncOp op,

    /// Version the client edited against; `0` for creates.
    required int baseVersion,

    /// Full entity snapshot for create/update, `{folder_id}` for move,
    /// empty for delete.
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = _SyncOpRequest;

  factory SyncOpRequest.fromJson(Map<String, Object?> json) =>
      _$SyncOpRequestFromJson(json);
}

/// Body of `POST /sync/push`.
@freezed
abstract class PushRequest with _$PushRequest {
  const factory PushRequest({
    required String deviceId,
    required List<SyncOpRequest> ops,
  }) = _PushRequest;

  factory PushRequest.fromJson(Map<String, Object?> json) =>
      _$PushRequestFromJson(json);
}
