import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.post});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final body = await readJsonObject(context);
  final PushRequest request;
  try {
    request = PushRequest.fromJson(body);
  } on Object {
    throw const ApiException.badRequest('Missing or invalid fields');
  }
  if (request.deviceId != auth.deviceId) {
    throw const ApiException(
      ApiErrorCode.forbidden,
      'device_id does not match the access token',
    );
  }
  final response = await context.read<ServerContext>().sync.push(
    userId: auth.userId,
    deviceId: auth.deviceId,
    request: request,
  );
  return json(response.toJson());
}
