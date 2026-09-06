import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vf_core/src/result/failure.dart';

/// Either a successful value ([Ok]) or a [Failure] ([Err]).
///
/// Prefer returning `Result` from use cases and repositories instead of
/// throwing, so callers are forced to handle failures. Use [guard] to wrap
/// throwing code at the boundary.
@immutable
sealed class Result<T> {
  const Result();

  /// Wraps [value] in an [Ok].
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps [failure] in an [Err].
  const factory Result.err(Failure failure) = Err<T>;

  /// Runs [body] and converts thrown errors into an [Err].
  ///
  /// [onError] maps an arbitrary error to a [Failure]; by default everything
  /// becomes an [UnexpectedFailure]. A thrown [Failure] is passed through.
  static Future<Result<T>> guard<T>(
    FutureOr<T> Function() body, {
    Failure Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return Ok(await body());
    } on Failure catch (failure) {
      return Err(failure);
    } on Object catch (error, stackTrace) {
      return Err(_mapError(error, stackTrace, onError));
    }
  }

  /// Synchronous variant of [guard].
  static Result<T> guardSync<T>(
    T Function() body, {
    Failure Function(Object error, StackTrace stackTrace)? onError,
  }) {
    try {
      return Ok(body());
    } on Failure catch (failure) {
      return Err(failure);
    } on Object catch (error, stackTrace) {
      return Err(_mapError(error, stackTrace, onError));
    }
  }

  static Failure _mapError(
    Object error,
    StackTrace stackTrace,
    Failure Function(Object error, StackTrace stackTrace)? onError,
  ) =>
      onError?.call(error, stackTrace) ??
      UnexpectedFailure(error.toString(), cause: error, stackTrace: stackTrace);

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value if [isOk], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure if [isErr], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Folds both branches into a single value.
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final failure) => err(failure),
  };

  /// Transforms the value, leaving failures untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Transforms the failure, leaving values untouched.
  Result<T> mapErr(Failure Function(Failure failure) transform) =>
      switch (this) {
        Ok() => this,
        Err(:final failure) => Err(transform(failure)),
      };

  /// Chains another fallible computation.
  Result<R> flatMap<R>(Result<R> Function(T value) next) => switch (this) {
    Ok(:final value) => next(value),
    Err(:final failure) => Err(failure),
  };

  /// Async variant of [flatMap].
  Future<Result<R>> flatMapAsync<R>(
    FutureOr<Result<R>> Function(T value) next,
  ) async => switch (this) {
    Ok(:final value) => await next(value),
    Err(:final failure) => Err(failure),
  };

  /// Returns the value or [fallback] when this is an [Err].
  T getOrElse(T Function(Failure failure) fallback) => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => fallback(failure),
  };

  /// Returns the value or throws the [Failure].
  ///
  /// Only use at boundaries where a failure is truly unrecoverable.
  T getOrThrow() => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// Successful [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Convenience for `Result<void>` successes.
const Result<void> okVoid = Ok(null);

extension FutureResultX<T> on Future<Result<T>> {
  /// [Result.map] lifted over a `Future`.
  Future<Result<R>> mapOk<R>(R Function(T value) transform) async =>
      (await this).map(transform);

  /// [Result.flatMapAsync] lifted over a `Future`.
  Future<Result<R>> andThen<R>(
    FutureOr<Result<R>> Function(T value) next,
  ) async {
    final result = await this;
    return await result.flatMapAsync(next);
  }
}
