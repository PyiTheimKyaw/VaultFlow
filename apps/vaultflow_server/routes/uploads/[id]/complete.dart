import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// `POST /uploads/{id}/complete`: assemble, verify, register the blob.
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = methodNotAllowed(context, {HttpMethod.post});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final server = context.read<ServerContext>();
  final response = await server.uploads.complete(
    auth.userId,
    auth.deviceId,
    id,
  );
  server.metrics
    ..increment('uploads_completed')
    ..increment(
      'upload_bytes',
      (await server.storage.sizeOf(response.storageKey)) ?? 0,
    );
  return json(response.toJson());
}
