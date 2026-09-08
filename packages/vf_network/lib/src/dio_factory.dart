import 'package:dio/dio.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/src/auth_interceptor.dart';
import 'package:vf_network/src/token_store.dart';

const _log = Logger('http');

/// Builds the app's single [Dio] instance.
abstract final class DioFactory {
  static Dio create({
    required String baseUrl,
    required TokenStore tokens,
    required void Function() onAuthLost,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    bool logRequests = false,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: receiveTimeout,
        headers: const {'Accept': 'application/json'},
        // Let the interceptor and ApiClient decide what a failure is.
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(dio: dio, tokens: tokens, onAuthLost: onAuthLost),
    );
    if (logRequests) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            _log.debug(
              '${response.requestOptions.method} '
              '${response.requestOptions.path} ${response.statusCode}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            _log.debug(
              '${error.requestOptions.method} ${error.requestOptions.path} '
              '${error.response?.statusCode ?? error.type.name}',
            );
            handler.next(error);
          },
        ),
      );
    }
    return dio;
  }
}
