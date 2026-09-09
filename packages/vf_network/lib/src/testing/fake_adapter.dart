import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A scripted [HttpClientAdapter]: routes are matched by `METHOD path`
/// (exact) or `METHOD prefix*`, and answered by a handler that sees the
/// request options. A streamed request body is collected into
/// `options.extra[FakeAdapter.bodyExtra]` before the handler runs.
class FakeAdapter implements HttpClientAdapter {
  static const String bodyExtra = 'fake.body';

  final Map<String, FutureOr<FakeResponse> Function(RequestOptions)> routes =
      {};
  final List<RequestOptions> calls = [];

  void on(
    String method,
    String path,
    FutureOr<FakeResponse> Function(RequestOptions options) handler,
  ) => routes['${method.toUpperCase()} $path'] = handler;

  FutureOr<FakeResponse> Function(RequestOptions)? _match(RequestOptions o) {
    final exact = routes['${o.method.toUpperCase()} ${o.path}'];
    if (exact != null) return exact;
    for (final entry in routes.entries) {
      final parts = entry.key.split(' ');
      if (parts[0] != o.method.toUpperCase()) continue;
      final pattern = parts[1];
      if (pattern.endsWith('*') &&
          o.path.startsWith(pattern.substring(0, pattern.length - 1))) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await requestStream.forEach(builder.add);
      options.extra[bodyExtra] = builder.takeBytes();
    }
    final handler = _match(options);
    if (handler == null) {
      return ResponseBody.fromString('not found', 404);
    }
    final response = await handler(options);
    final stream = response.stream;
    if (stream != null) {
      return ResponseBody(
        stream,
        response.status,
        headers: {
          for (final e in response.headers.entries) e.key: [e.value],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final e in response.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(
    this.status, [
    this.body = const <String, Object?>{},
    this.headers = const {},
  ]) : stream = null;

  /// A raw streamed body (downloads); [headers] carry ETag / Content-Range.
  const FakeResponse.stream(
    this.status,
    Stream<Uint8List> this.stream, {
    this.headers = const {},
  }) : body = const <String, Object?>{};

  final int status;
  final Object body;
  final Map<String, String> headers;
  final Stream<Uint8List>? stream;
}
