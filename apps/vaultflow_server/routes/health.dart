import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:vf_core/vf_core.dart';

/// Liveness probe. Returns 200 while the process is serving requests.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return Response.json(
    body: {
      'status': 'ok',
      'service': 'vaultflow_server',
      'core': vfCorePackageName,
      'time': DateTime.now().toUtc().toIso8601String(),
    },
  );
}
