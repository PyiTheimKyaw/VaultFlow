import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// Who am I: proves the access token works and lets the client restore its
/// session on launch.
Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get});
  if (rejected != null) return rejected;
  final claims = authenticate(context);
  final user = await context.read<ServerContext>().auth.userById(claims.userId);
  if (user == null) throw const ApiException.unauthorized();
  return json({
    'user_id': user.id,
    'email': user.email,
    'device_id': claims.deviceId,
  });
}
