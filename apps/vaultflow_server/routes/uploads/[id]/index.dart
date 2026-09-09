import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// `GET /uploads/{id}`: which chunks the server already has.
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final status = await context.read<ServerContext>().uploads.status(
    auth.userId,
    id,
  );
  return json(status.toJson());
}
