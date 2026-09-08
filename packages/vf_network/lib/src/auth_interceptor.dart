import 'dart:async';

import 'package:dio/dio.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/src/token_store.dart';
import 'package:vf_protocol/vf_protocol.dart';

const _log = Logger('auth_interceptor');

/// Set `extra[skipAuth] = true` on requests that must not carry or refresh
/// a token (login, register, refresh, logout).
const String skipAuthExtra = 'vf.skipAuth';
const String _retriedExtra = 'vf.retried';

/// Attaches the access token and, on 401, refreshes it exactly once for all
/// queued requests before replaying them.
///
/// [QueuedInterceptorsWrapper] serialises every callback, so while one
/// request is refreshing, later requests wait in the queue and then read the
/// new token from the store. Requests that failed with a token that has
/// already been replaced are simply retried with the current one.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required this.dio,
    required this.tokens,
    required this.onAuthLost,
  });

  /// The client the interceptor is installed on; used to replay requests
  /// and to call the refresh endpoint.
  final Dio dio;
  final TokenStore tokens;

  /// Called once when the session cannot be recovered.
  final void Function() onAuthLost;

  /// Number of refresh calls performed; exposed for tests.
  int refreshCount = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[ApiPaths.protocolHeader] = '$vfProtocolVersion';
    if (options.extra[skipAuthExtra] != true) {
      final current = await tokens.read();
      if (current != null) {
        options.headers['Authorization'] = 'Bearer ${current.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    if (!is401 ||
        options.extra[skipAuthExtra] == true ||
        options.extra[_retriedExtra] == true) {
      return handler.next(err);
    }

    final current = await tokens.read();
    if (current == null) {
      onAuthLost();
      return handler.next(err);
    }

    final usedToken = options.headers['Authorization'];
    AuthTokens fresh;
    if (usedToken != 'Bearer ${current.accessToken}') {
      // Another request already refreshed while this one was in flight.
      fresh = current;
    } else {
      try {
        fresh = await _refresh(current);
      } on Object catch (error) {
        _log.warning('token refresh failed', error: error);
        await tokens.clear();
        onAuthLost();
        return handler.next(err);
      }
    }

    // Replay through the bare client for the same reason as the refresh:
    // a second 401 must reach us as a plain exception, not re-enter the
    // queue we are currently blocking.
    try {
      final response = await _refreshClient.fetch<Object?>(
        options
          ..headers['Authorization'] = 'Bearer ${fresh.accessToken}'
          ..extra[_retriedExtra] = true,
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Refresh and replay calls must not pass through this (queued)
  /// interceptor, otherwise they would wait for the very callback that is
  /// awaiting them. A bare client sharing the same options and adapter is
  /// used instead.
  Dio get _refreshClient =>
      _refreshDio ??= Dio(dio.options)
        ..httpClientAdapter = dio.httpClientAdapter;
  Dio? _refreshDio;

  Future<AuthTokens> _refresh(AuthTokens current) async {
    refreshCount++;
    final response = await _refreshClient.post<Map<String, Object?>>(
      ApiPaths.authRefresh,
      data: RefreshRequest(
        refreshToken: current.refreshToken,
        deviceId: current.deviceId,
      ).toJson(),
      options: Options(
        headers: {ApiPaths.protocolHeader: '$vfProtocolVersion'},
      ),
    );
    final fresh = AuthTokens.fromJson(response.data!);
    await tokens.write(fresh);
    return fresh;
  }
}
