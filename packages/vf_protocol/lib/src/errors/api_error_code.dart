import 'package:json_annotation/json_annotation.dart';

/// Machine-readable error codes returned in `ApiError.code`.
@JsonEnum(fieldRename: FieldRename.snake)
enum ApiErrorCode {
  badRequest,
  validationFailed,
  unauthorized,
  tokenExpired,
  tokenRevoked,
  forbidden,
  notFound,
  conflict,
  emailTaken,
  payloadTooLarge,
  uploadExpired,
  chunkMismatch,
  hashMismatch,
  rateLimited,
  protocolUnsupported,
  internal;

  /// Default HTTP status for each code.
  int get httpStatus => switch (this) {
    badRequest || validationFailed => 400,
    unauthorized || tokenExpired || tokenRevoked => 401,
    forbidden => 403,
    notFound || uploadExpired => 404,
    conflict || emailTaken => 409,
    payloadTooLarge => 413,
    chunkMismatch || hashMismatch => 422,
    rateLimited => 429,
    protocolUnsupported => 426,
    internal => 500,
  };

  /// Parses a wire value, falling back to [internal] for unknown codes so an
  /// older client never crashes on a newer server.
  static ApiErrorCode fromWire(String? value) => values.firstWhere(
    (e) => _wireName(e) == value,
    orElse: () => ApiErrorCode.internal,
  );

  static String _wireName(ApiErrorCode code) => code.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
}
