import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// Root middleware, innermost first: dependency provider, request logging,
/// rate limiting, request id, error mapping, metrics, security headers,
/// then CORS on the outside so error responses and preflights carry the
/// headers too.
Handler middleware(Handler handler) {
  final server = globalServerContext();
  return handler
      .use(provider<ServerContext>((_) => server))
      .use(requestLogger())
      .use(
        rateLimit(
          server.limiter,
          keyFor: (c) =>
              userOrClientKey(c, trustProxy: server.config.trustProxy),
        ),
      )
      .use(requestId())
      .use(errorHandler(onUnhandled: server.reportError))
      // Outside the error handler so 4xx/5xx envelopes are counted with
      // their real status.
      .use(recordMetrics(server.metrics))
      .use(securityHeaders())
      .use(trackInFlight(server.inFlight))
      .use(cors(server.config.corsAllowedOrigins));
}
