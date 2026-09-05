import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {'service': 'vaultflow_server', 'docs': '/health'},
  );
}
