import 'package:dart_frog/dart_frog.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Thrown anywhere in a request; `errorHandler()` turns it into the standard
/// `{"error": {...}}` envelope with the code's HTTP status.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.details, this.headers});

  const ApiException.badRequest(String message, {Map<String, Object?>? details})
    : this(ApiErrorCode.badRequest, message, details: details);

  const ApiException.validation(String message, {Map<String, Object?>? details})
    : this(ApiErrorCode.validationFailed, message, details: details);

  const ApiException.unauthorized([String message = 'Authentication required'])
    : this(ApiErrorCode.unauthorized, message);

  const ApiException.notFound([String message = 'Not found'])
    : this(ApiErrorCode.notFound, message);

  final ApiErrorCode code;
  final String message;
  final Map<String, Object?>? details;

  ApiError get error =>
      ApiError(code: code, message: message, details: details);

  /// Extra response headers (`Retry-After` for 429).
  final Map<String, String>? headers;

  Response toResponse() => Response.json(
    statusCode: code.httpStatus,
    body: error.toEnvelope(),
    headers: headers ?? const {},
  );

  @override
  String toString() => 'ApiException(${code.name}: $message)';
}
