import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// `POST /uploads`: starts a session or reports an instant dedupe hit.
Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.post});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final body = await readJsonObject(context);
  final UploadSessionCreateRequest request;
  try {
    request = UploadSessionCreateRequest.fromJson(body);
  } on Object {
    throw const ApiException.badRequest('Missing or invalid fields');
  }
  final response = await context.read<ServerContext>().uploads.create(
    auth.userId,
    request,
  );
  return json(response.toJson(), statusCode: response.dedup ? 200 : 201);
}
