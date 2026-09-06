import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/src/errors/api_error_code.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

/// Body of every non-2xx response: `{"error": {code, message, details}}`.
@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({
    required ApiErrorCode code,
    required String message,
    Map<String, Object?>? details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, Object?> json) =>
      _$ApiErrorFromJson(json);

  /// Unwraps the `{"error": {...}}` envelope.
  factory ApiError.fromEnvelope(Map<String, Object?> json) =>
      ApiError.fromJson((json['error'] ?? json) as Map<String, Object?>);
}

/// Wraps an [ApiError] in the standard envelope.
extension ApiErrorEnvelope on ApiError {
  Map<String, Object?> toEnvelope() => {'error': toJson()};
}
