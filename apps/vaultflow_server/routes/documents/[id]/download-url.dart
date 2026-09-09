// dart_frog maps the file name to the URL segment `download-url`.
// ignore_for_file: file_names
import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// `POST /documents/{id}/download-url`: a short-lived link for browsers.
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = methodNotAllowed(context, {HttpMethod.post});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final server = context.read<ServerContext>();
  // Only documents the caller owns and that have content.
  await server.content.describe(auth.userId, id);
  final ttl = server.config.downloadLinkTtl;
  final token = server.tokens.signDownloadToken(
    userId: auth.userId,
    documentId: id,
    ttl: ttl,
  );
  return json(
    DownloadUrlResponse(
      url: Uri(
        path: ApiPaths.documentContent(id),
        queryParameters: {ApiPaths.downloadTokenParam: token},
      ).toString(),
      expiresAt: server.clock.now().add(ttl),
    ).toJson(),
  );
}
