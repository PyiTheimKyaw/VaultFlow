// dart_frog dynamic route: the file name is the path parameter. It is `n`
// rather than `index` because `index.dart` is dart_frog's directory route
// and the generated server would not compile.
// ignore_for_file: file_names
import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// `PUT /uploads/{id}/chunks/{n}`: raw chunk bytes.
Future<Response> onRequest(RequestContext context, String id, String n) async {
  final rejected = methodNotAllowed(context, {HttpMethod.put});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final server = context.read<ServerContext>();
  final chunkIndex = int.tryParse(n);
  if (chunkIndex == null || chunkIndex < 0) {
    throw const ApiException.badRequest(
      'chunk index must be a non-negative integer',
    );
  }
  final declaredLength = int.tryParse(
    context.request.headers['content-length'] ?? '',
  );
  if (declaredLength != null && declaredLength > server.config.maxChunkSize) {
    throw const ApiException(ApiErrorCode.payloadTooLarge, 'Chunk too large');
  }
  final bytes = await readBoundedBody(context, server.config.maxChunkSize);
  final response = await server.uploads.putChunk(
    auth.userId,
    id,
    chunkIndex,
    bytes,
    declaredSha256:
        context.request.headers[ApiPaths.chunkHashHeader.toLowerCase()],
  );
  return json(response.toJson());
}
