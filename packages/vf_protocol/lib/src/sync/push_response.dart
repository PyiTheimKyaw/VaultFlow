import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/src/enums/sync_op_status.dart';

part 'push_response.freezed.dart';
part 'push_response.g.dart';

/// Result of one pushed op, in the same order as the request.
@freezed
abstract class SyncOpResult with _$SyncOpResult {
  const factory SyncOpResult({
    required String clientOpId,
    required SyncOpStatus status,

    /// Set when [status] is [SyncOpStatus.applied].
    int? newVersion,

    /// Server snapshot, set when [status] is [SyncOpStatus.conflict].
    Map<String, Object?>? remote,
    int? remoteVersion,

    /// Human-readable reason, set when [status] is [SyncOpStatus.rejected].
    String? error,
  }) = _SyncOpResult;

  factory SyncOpResult.fromJson(Map<String, Object?> json) =>
      _$SyncOpResultFromJson(json);
}

/// Body of the `POST /sync/push` response.
@freezed
abstract class PushResponse with _$PushResponse {
  const factory PushResponse({required List<SyncOpResult> results}) =
      _PushResponse;

  factory PushResponse.fromJson(Map<String, Object?> json) =>
      _$PushResponseFromJson(json);
}
