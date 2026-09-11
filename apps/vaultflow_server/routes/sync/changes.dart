import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final query = context.request.uri.queryParameters;
  final since = int.tryParse(query['since'] ?? '0');
  final limit = int.tryParse(query['limit'] ?? '500')?.clamp(1, 500);
  if (since == null || since < 0 || limit == null || limit < 1) {
    throw const ApiException.badRequest(
      'since and limit must be non-negative integers',
    );
  }
  final response = await context.read<ServerContext>().sync.changes(
    userId: auth.userId,
    since: since,
    limit: limit,
    excludeDeviceId: query['exclude_device'],
  );
  return json(response.toJson());
}
