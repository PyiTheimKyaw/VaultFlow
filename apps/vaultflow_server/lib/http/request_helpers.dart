import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/server_context.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// Parses the JSON object body or throws a 400. Bodies larger than
/// `ServerConfig.maxJsonBodyBytes` are refused with 413 before parsing.
Future<Map<String, Object?>> readJsonObject(RequestContext context) async {
  final limit = context.read<ServerContext>().config.maxJsonBodyBytes;
  final raw = await readBoundedBody(context, limit);
  final Object? body;
  try {
    body = jsonDecode(utf8.decode(raw));
  } on FormatException {
    throw const ApiException.badRequest('Body must be valid JSON');
  }
  if (body is! Map<String, Object?>) {
    throw const ApiException.badRequest('Body must be a JSON object');
  }
  return body;
}

/// Rejects every method except [allowed] with 405.
Response? methodNotAllowed(RequestContext context, Set<HttpMethod> allowed) {
  if (allowed.contains(context.request.method)) return null;
  return Response(
    statusCode: 405,
    headers: {'allow': allowed.map((m) => m.value).join(', ')},
  );
}

/// Reads the raw body, refusing anything larger than [maxBytes] with 413.
Future<List<int>> readBoundedBody(RequestContext context, int maxBytes) async {
  final declared = int.tryParse(
    context.request.headers['content-length'] ?? '',
  );
  if (declared != null && declared > maxBytes) {
    throw const ApiException(ApiErrorCode.payloadTooLarge, 'Body too large');
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in context.request.bytes()) {
    builder.add(chunk);
    if (builder.length > maxBytes) {
      throw const ApiException(ApiErrorCode.payloadTooLarge, 'Body too large');
    }
  }
  return builder.takeBytes();
}

/// Bearer token from the Authorization header, or `null`.
String? bearerToken(RequestContext context) {
  final header = context.request.headers['authorization'];
  if (header == null) return null;
  const prefix = 'Bearer ';
  if (!header.startsWith(prefix)) return null;
  final token = header.substring(prefix.length).trim();
  return token.isEmpty ? null : token;
}

/// JSON response with a body map, defaulting to 200.
Response json(Map<String, Object?> body, {int statusCode = 200}) =>
    Response.json(statusCode: statusCode, body: body);

/// 204 with no body.
Response noContent() => Response(statusCode: 204, body: '');

/// Used in tests to decode a response body.
Future<Map<String, Object?>> decodeJson(Response response) async =>
    jsonDecode(await response.body()) as Map<String, Object?>;
