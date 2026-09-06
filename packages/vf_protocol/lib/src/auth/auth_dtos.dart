import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

/// Body of `POST /auth/register` and `POST /auth/login`.
@freezed
abstract class CredentialsRequest with _$CredentialsRequest {
  const factory CredentialsRequest({
    required String email,
    required String password,

    /// Human-readable device name shown in session lists.
    required String deviceName,

    /// `android | ios | macos | windows | linux | web`.
    required String platform,

    /// Existing device id when re-authenticating from a known device.
    String? deviceId,
  }) = _CredentialsRequest;

  factory CredentialsRequest.fromJson(Map<String, Object?> json) =>
      _$CredentialsRequestFromJson(json);
}

/// Body of `POST /auth/refresh` and `POST /auth/logout`.
@freezed
abstract class RefreshRequest with _$RefreshRequest {
  const factory RefreshRequest({
    required String refreshToken,
    required String deviceId,
  }) = _RefreshRequest;

  factory RefreshRequest.fromJson(Map<String, Object?> json) =>
      _$RefreshRequestFromJson(json);
}

/// Response of register / login / refresh.
@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required String deviceId,
    required String userId,

    /// Access-token lifetime in seconds.
    required int expiresIn,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, Object?> json) =>
      _$AuthTokensFromJson(json);
}
