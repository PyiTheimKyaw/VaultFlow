import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.post});
  if (rejected != null) return rejected;
  final body = await readJsonObject(context);
  final RefreshRequest request;
  try {
    request = RefreshRequest.fromJson(body);
  } on Object {
    throw const ApiException.badRequest('Missing or invalid fields');
  }
  final tokens = await context.read<ServerContext>().auth.refresh(request);
  return json(tokens.toJson());
}
