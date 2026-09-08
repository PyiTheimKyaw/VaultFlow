import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// Root middleware, innermost first: dependency provider, request logging,
/// request id, error mapping, then CORS on the outside so error responses
/// and preflights carry the headers too.
Handler middleware(Handler handler) {
  return handler
      .use(provider<ServerContext>((_) => globalServerContext()))
      .use(requestLogger())
      .use(requestId())
      .use(errorHandler())
      .use(cors(globalServerContext().config.corsAllowedOrigins));
}
