import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_url_dtos.freezed.dart';
part 'download_url_dtos.g.dart';

/// `POST /documents/{id}/download-url` → a short-lived link a browser can
/// open directly (no `Authorization` header needed). Used on web, where
/// the app cannot write ranged `.part` files.
@freezed
abstract class DownloadUrlResponse with _$DownloadUrlResponse {
  const factory DownloadUrlResponse({
    /// Path relative to the API origin, e.g. `/documents/x/content?token=…`.
    required String url,
    required DateTime expiresAt,
  }) = _DownloadUrlResponse;

  factory DownloadUrlResponse.fromJson(Map<String, Object?> json) =>
      _$DownloadUrlResponseFromJson(json);
}

/// One `GET /sync/events` message: the newest change sequence for the user.
@freezed
abstract class SyncEvent with _$SyncEvent {
  const factory SyncEvent({required int seq}) = _SyncEvent;

  factory SyncEvent.fromJson(Map<String, Object?> json) =>
      _$SyncEventFromJson(json);
}
