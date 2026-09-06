import 'package:meta/meta.dart';

/// Base class for every recoverable error surfaced through a `Result`.
///
/// Failures are plain values: they carry a human-readable [message], an
/// optional [cause] (the original exception) and its [stackTrace]. Subclasses
/// describe *where* things went wrong so callers can branch on the type
/// instead of parsing strings.
@immutable
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  /// Short type label used by [toString]; overridden per subclass.
  String get kind;

  @override
  String toString() => '$kind($message)';
}

/// The device could not reach the server (offline, DNS, timeout, TLS).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'NetworkFailure';
}

/// The server answered with an error status.
final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    required this.statusCode,
    this.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String get kind => 'ServerFailure';

  /// HTTP status code returned by the server.
  final int statusCode;

  /// Machine-readable error code from the API body, when present.
  final String? code;

  @override
  String toString() => 'ServerFailure($statusCode ${code ?? ''} $message)';
}

/// The current session is missing, expired or revoked.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'AuthFailure';
}

/// A local database or filesystem operation failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'StorageFailure';
}

/// Input did not satisfy a domain invariant (empty name, bad path, …).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field, super.cause});

  @override
  String get kind => 'ValidationFailure';

  /// The offending field, when the failure concerns a single one.
  final String? field;
}

/// The requested entity does not exist (or is tombstoned).
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'NotFoundFailure';
}

/// A sync push was rejected because the server version moved on.
final class ConflictFailure extends Failure {
  const ConflictFailure(
    super.message, {
    required this.remoteVersion,
    super.cause,
  });

  @override
  String get kind => 'ConflictFailure';

  final int remoteVersion;
}

/// The user or a caller cancelled the operation.
final class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Cancelled']);

  @override
  String get kind => 'CancelledFailure';
}

/// Anything that does not fit one of the categories above.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'UnexpectedFailure';
}
