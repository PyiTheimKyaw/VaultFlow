import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/src/enums/entity_type.dart';
import 'package:vf_protocol/src/enums/sync_op.dart';

part 'changes_response.freezed.dart';
part 'changes_response.g.dart';

/// One row of the server's append-only change feed.
@freezed
abstract class ChangeDto with _$ChangeDto {
  const factory ChangeDto({
    /// Monotonic sequence number; the pull cursor.
    required int seq,
    required EntityType entityType,
    required String entityId,
    required SyncOp op,
    required int version,
    required String deviceId,
    required DateTime createdAt,

    /// Entity snapshot after the change (empty for deletes).
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = _ChangeDto;

  factory ChangeDto.fromJson(Map<String, Object?> json) =>
      _$ChangeDtoFromJson(json);
}

/// Body of the `GET /sync/changes` response.
@freezed
abstract class ChangesResponse with _$ChangesResponse {
  const factory ChangesResponse({
    required List<ChangeDto> changes,

    /// Pass as `since` on the next call.
    required int nextCursor,
    required bool hasMore,
  }) = _ChangesResponse;

  factory ChangesResponse.fromJson(Map<String, Object?> json) =>
      _$ChangesResponseFromJson(json);
}
