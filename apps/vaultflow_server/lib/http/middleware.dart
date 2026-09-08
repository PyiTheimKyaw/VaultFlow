import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/auth/token_service.dart';
import 'package:vaultflow_server/http/api_exception.dart';
import 'package:vaultflow_server/http/request_helpers.dart';
import 'package:vaultflow_server/server_context.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

const _log = Logger('http');

/// Identity of the caller, provided by [authRequired].
class AuthContext {
  const AuthContext({required this.userId, required this.deviceId});

  final String userId;
  final String deviceId;
}

/// Request id carried through the pipeline and echoed in the response.
class RequestId {
  const RequestId(this.value);
  final String value;
}

/// Echoes or assigns an `X-Request-Id` header and makes it readable via
/// `context.read<RequestId>()`.
Middleware requestId() {
  return (handler) => (context) async {
    final incoming =
        context.request.headers[ApiPaths.requestIdHeader.toLowerCase()];
    final id = incoming == null || incoming.isEmpty ? VfId.random() : incoming;
    final response = await handler(
      context.provide<RequestId>(() => RequestId(id)),
    );
    return response.copyWith(
      headers: {...response.headers, ApiPaths.requestIdHeader: id},
    );
  };
}

/// Converts [ApiException]s and unexpected errors into the error envelope.
Middleware errorHandler() {
  return (handler) => (context) async {
    try {
      return await handler(context);
    } on ApiException catch (e) {
      return e.toResponse();
    } on Object catch (error, stackTrace) {
      _log.error('unhandled error', error: error, stackTrace: stackTrace);
      return const ApiException(
        ApiErrorCode.internal,
        'Internal server error',
      ).toResponse();
    }
  };
}

/// Minimal CORS for browser clients. [allowedOrigins] may contain `*`.
Middleware cors(List<String> allowedOrigins) {
  return (handler) => (context) async {
    final origin = context.request.headers['origin'];
    final allowed =
        origin != null &&
        (allowedOrigins.contains('*') || allowedOrigins.contains(origin));
    final headers = <String, String>{
      if (allowed) 'Access-Control-Allow-Origin': origin,
      if (allowed) 'Vary': 'Origin',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Authorization, Content-Type, ${ApiPaths.protocolHeader}, '
          '${ApiPaths.chunkHashHeader}, ${ApiPaths.requestIdHeader}, Range',
      'Access-Control-Expose-Headers':
          '${ApiPaths.requestIdHeader}, ETag, Accept-Ranges, Content-Range',
      'Access-Control-Max-Age': '600',
    };
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: headers, body: '');
    }
    final response = await handler(context);
    return response.copyWith(headers: {...response.headers, ...headers});
  };
}

/// Requires a valid bearer access token and provides [AuthContext].
Middleware authRequired() {
  return (handler) => (context) async {
    final claims = authenticate(context);
    return await handler(
      context.provide<AuthContext>(
        () => AuthContext(userId: claims.userId, deviceId: claims.deviceId),
      ),
    );
  };
}

/// Verifies the bearer token on [context]; throws [ApiException] on failure.
AccessClaims authenticate(RequestContext context) {
  final token = bearerToken(context);
  if (token == null) throw const ApiException.unauthorized();
  try {
    return context.read<ServerContext>().tokens.verifyAccessToken(token);
  } on AccessTokenException catch (e) {
    throw ApiException(
      e.reason == AccessTokenError.expired
          ? ApiErrorCode.tokenExpired
          : ApiErrorCode.unauthorized,
      e.reason == AccessTokenError.expired
          ? 'Access token expired'
          : 'Invalid access token',
    );
  }
}
