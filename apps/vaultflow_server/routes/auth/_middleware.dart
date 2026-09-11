import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// Credential endpoints get a much smaller per-address budget than the
/// rest of the API (brute force, enumeration).
Handler middleware(Handler handler) {
  final server = globalServerContext();
  return handler.use(
    rateLimit(
      server.authLimiter,
      keyFor: (c) =>
          'auth:${clientKey(c, trustProxy: server.config.trustProxy)}',
    ),
  );
}
