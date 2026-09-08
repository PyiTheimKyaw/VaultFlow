import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A scripted [HttpClientAdapter]: routes are matched by `METHOD path` and
/// answered by a handler that sees the request options.
class FakeAdapter implements HttpClientAdapter {
  final Map<String, FutureOr<FakeResponse> Function(RequestOptions)> routes =
      {};
  final List<RequestOptions> calls = [];

  void on(
    String method,
    String path,
    FutureOr<FakeResponse> Function(RequestOptions options) handler,
  ) => routes['${method.toUpperCase()} $path'] = handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final handler = routes['${options.method.toUpperCase()} ${options.path}'];
    if (handler == null) {
      return ResponseBody.fromString('not found', 404);
    }
    final response = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(this.status, [this.body = const <String, Object?>{}]);
  final int status;
  final Object body;
}
