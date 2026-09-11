import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// `GET /metrics` in Prometheus text format. Enabled only when
/// `METRICS_TOKEN` is configured and presented as a bearer token.
Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get});
  if (rejected != null) return rejected;
  final server = context.read<ServerContext>();
  final expected = server.config.metricsToken;
  if (expected == null) throw const ApiException.notFound();
  if (bearerToken(context) != expected) {
    throw const ApiException.unauthorized('Metrics token required');
  }
  return Response(
    headers: {'Content-Type': 'text/plain; version=0.0.4; charset=utf-8'},
    body: server.metrics.render(),
  );
}
