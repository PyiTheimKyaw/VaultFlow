import 'package:dart_frog/dart_frog.dart';
import 'package:vf_core/vf_core.dart';

/// Process-local counters exposed in Prometheus text format at `/metrics`.
///
/// Routes are normalised to their pattern (`/uploads/{id}/chunks/{n}`) so
/// ids never blow up the label space.
class Metrics {
  Metrics({this.clock = const SystemClock()});

  final Clock clock;
  final Map<String, int> _requests = {};
  final Map<String, double> _latencySum = {};
  final Map<String, int> _latencyCount = {};
  final Map<String, int> _counters = {};

  void recordRequest(String method, String route, int status, Duration took) {
    final key = '$method|$route|$status';
    _requests.update(key, (n) => n + 1, ifAbsent: () => 1);
    final lkey = '$method|$route';
    _latencySum.update(
      lkey,
      (t) => t + took.inMicroseconds / 1e6,
      ifAbsent: () => took.inMicroseconds / 1e6,
    );
    _latencyCount.update(lkey, (n) => n + 1, ifAbsent: () => 1);
  }

  /// Business counters: `sync_ops_applied`, `sync_conflicts`,
  /// `upload_bytes`, `upload_completed`, `download_bytes`…
  void increment(String name, [int by = 1]) =>
      _counters.update(name, (n) => n + by, ifAbsent: () => by);

  int counter(String name) => _counters[name] ?? 0;

  Map<String, int> get requests => Map.unmodifiable(_requests);

  static final RegExp _uuidish = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static final RegExp _digits = RegExp(r'^\d+$');

  /// `/uploads/<uuid>/chunks/3` → `/uploads/{id}/chunks/{n}`.
  static String normalise(String path) => path
      .split('/')
      .map(
        (seg) => _uuidish.hasMatch(seg)
            ? '{id}'
            : _digits.hasMatch(seg)
            ? '{n}'
            : seg,
      )
      .join('/');

  String render() {
    final b = StringBuffer()
      ..writeln('# HELP vaultflow_http_requests_total HTTP requests.')
      ..writeln('# TYPE vaultflow_http_requests_total counter');
    for (final e in _requests.entries) {
      final [method, route, status] = e.key.split('|');
      b.writeln(
        'vaultflow_http_requests_total{method="$method",route="$route",'
        'status="$status"} ${e.value}',
      );
    }
    b
      ..writeln('# HELP vaultflow_http_request_seconds Request latency.')
      ..writeln('# TYPE vaultflow_http_request_seconds summary');
    for (final e in _latencySum.entries) {
      final [method, route] = e.key.split('|');
      b
        ..writeln(
          'vaultflow_http_request_seconds_sum{method="$method",'
          'route="$route"} ${e.value.toStringAsFixed(6)}',
        )
        ..writeln(
          'vaultflow_http_request_seconds_count{method="$method",'
          'route="$route"} ${_latencyCount[e.key]}',
        );
    }
    for (final e in _counters.entries) {
      b
        ..writeln('# TYPE vaultflow_${e.key}_total counter')
        ..writeln('vaultflow_${e.key}_total ${e.value}');
    }
    return b.toString();
  }
}

/// Records every request's method, normalised route, status and latency.
Middleware recordMetrics(Metrics metrics) {
  return (handler) => (context) async {
    final started = metrics.clock.now();
    final route = Metrics.normalise(
      '/${context.request.uri.path.replaceFirst(RegExp('^/+'), '')}',
    );
    try {
      final response = await handler(context);
      metrics.recordRequest(
        context.request.method.value,
        route,
        response.statusCode,
        metrics.clock.now().difference(started),
      );
      return response;
    } on Object {
      metrics.recordRequest(
        context.request.method.value,
        route,
        500,
        metrics.clock.now().difference(started),
      );
      rethrow;
    }
  };
}
