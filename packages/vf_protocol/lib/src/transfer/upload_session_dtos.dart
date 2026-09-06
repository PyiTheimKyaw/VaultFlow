import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_session_dtos.freezed.dart';
part 'upload_session_dtos.g.dart';

/// Lifecycle of an upload session as seen by the server.
@JsonEnum(fieldRename: FieldRename.snake)
enum UploadSessionState { active, completed, expired, aborted }

/// Body of `POST /uploads`.
@freezed
abstract class UploadSessionCreateRequest with _$UploadSessionCreateRequest {
  const factory UploadSessionCreateRequest({
    required String documentId,
    required int totalBytes,
    required String sha256,
    required String mimeType,
    required int chunkSize,
  }) = _UploadSessionCreateRequest;

  factory UploadSessionCreateRequest.fromJson(Map<String, Object?> json) =>
      _$UploadSessionCreateRequestFromJson(json);
}

/// Response of `POST /uploads`.
///
/// Either a new session ([uploadId] set) or an instant dedupe hit
/// ([dedup] true and [storageKey] set, no bytes need to be sent).
@freezed
abstract class UploadSessionResponse with _$UploadSessionResponse {
  const factory UploadSessionResponse({
    @Default(false) bool dedup,
    String? uploadId,
    int? chunkSize,
    DateTime? expiresAt,
    String? storageKey,
  }) = _UploadSessionResponse;

  factory UploadSessionResponse.fromJson(Map<String, Object?> json) =>
      _$UploadSessionResponseFromJson(json);
}

/// Response of `GET /uploads/{id}`; used to reconcile before resuming.
@freezed
abstract class UploadSessionStatus with _$UploadSessionStatus {
  const factory UploadSessionStatus({
    required String uploadId,
    required UploadSessionState state,
    required int totalBytes,
    required int chunkSize,
    required List<int> receivedChunks,
    required DateTime expiresAt,
  }) = _UploadSessionStatus;

  factory UploadSessionStatus.fromJson(Map<String, Object?> json) =>
      _$UploadSessionStatusFromJson(json);
}

/// Response of `PUT /uploads/{id}/chunks/{idx}`.
@freezed
abstract class UploadChunkResponse with _$UploadChunkResponse {
  const factory UploadChunkResponse({
    required int index,
    required int receivedCount,
    String? etag,
  }) = _UploadChunkResponse;

  factory UploadChunkResponse.fromJson(Map<String, Object?> json) =>
      _$UploadChunkResponseFromJson(json);
}

/// Response of `POST /uploads/{id}/complete`.
@freezed
abstract class UploadCompleteResponse with _$UploadCompleteResponse {
  const factory UploadCompleteResponse({
    required String documentId,
    required int version,
    required String storageKey,
  }) = _UploadCompleteResponse;

  factory UploadCompleteResponse.fromJson(Map<String, Object?> json) =>
      _$UploadCompleteResponseFromJson(json);
}
