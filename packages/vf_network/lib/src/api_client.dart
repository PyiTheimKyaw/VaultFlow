import 'package:dio/dio.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/src/auth_interceptor.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Typed access to the VaultFlow API. Every call returns a [Result]; the
/// error side is one of [NetworkFailure], [AuthFailure], [ServerFailure]
/// or [CancelledFailure].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  static final Options _public = Options(extra: {skipAuthExtra: true});

  Future<Result<AuthTokens>> register(CredentialsRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authRegister,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<AuthTokens>> login(CredentialsRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authLogin,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<AuthTokens>> refresh(RefreshRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.authRefresh,
      data: request.toJson(),
      options: _public,
    ),
    AuthTokens.fromJson,
  );

  Future<Result<void>> logout(RefreshRequest request) => _run(
    () => _dio.post<Object?>(
      ApiPaths.authLogout,
      data: request.toJson(),
      options: _public,
    ),
    (_) {},
  );

  // ------------------------------------------------------------------ sync

  Future<Result<PushResponse>> push(PushRequest request) => _run(
    () => _dio.post<Map<String, Object?>>(
      ApiPaths.syncPush,
      data: request.toJson(),
    ),
    PushResponse.fromJson,
  );

  Future<Result<ChangesResponse>> changes({
    required int since,
    int limit = vfMaxChangesPageSize,
    String? excludeDeviceId,
  }) => _run(
    () => _dio.get<Map<String, Object?>>(
      ApiPaths.syncChanges,
      queryParameters: {
        'since': since,
        'limit': limit,
        'exclude_device': ?excludeDeviceId,
      },
    ),
    ChangesResponse.fromJson,
  );

  Future<Result<MeResponse>> me() => _run(
    () => _dio.get<Map<String, Object?>>(ApiPaths.authMe),
    MeResponse.fromJson,
  );

  Future<Result<T>> _run<T, R>(
    Future<Response<R>> Function() call,
    T Function(R data) parse,
  ) async {
    try {
      final response = await call();
      return Ok(parse(response.data as R));
    } on DioException catch (e, stackTrace) {
      return Err(mapDioException(e, stackTrace));
    } on Object catch (e, stackTrace) {
      return Err(
        UnexpectedFailure('Bad response: $e', cause: e, stackTrace: stackTrace),
      );
    }
  }

  /// Converts a [DioException] into the domain [Failure] hierarchy.
  static Failure mapDioException(DioException e, [StackTrace? stackTrace]) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(
          'Cannot reach the server',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badCertificate:
        return NetworkFailure(
          'Untrusted server certificate',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final apiError = _parseError(e.response?.data);
        final message = apiError?.message ?? 'Request failed ($status)';
        if (status == 401) {
          return AuthFailure(message, cause: e, stackTrace: stackTrace);
        }
        return ServerFailure(
          message,
          statusCode: status,
          code: apiError == null ? null : _wireName(apiError.code),
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        return NetworkFailure(
          e.message ?? 'Network error',
          cause: e,
          stackTrace: stackTrace,
        );
    }
  }

  static ApiError? _parseError(Object? data) {
    if (data is! Map<String, Object?>) return null;
    try {
      return ApiError.fromEnvelope(data);
    } on Object {
      return null;
    }
  }

  static String _wireName(ApiErrorCode code) => code.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
}
