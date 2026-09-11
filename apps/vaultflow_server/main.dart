import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:sentry/sentry.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';

const _log = Logger('server');

/// dart_frog custom entrypoint: log format, Sentry, and a graceful shutdown
/// on SIGTERM/SIGINT (stop accepting, let in-flight requests finish within
/// `SHUTDOWN_GRACE_SECONDS`, close the database pool).
Future<void> init(InternetAddress ip, int port) async {
  final server = globalServerContext();
  final config = server.config;
  Logger.minimumLevel = LogLevel.info;
  if (config.logFormat == LogFormat.json) Logger.sink = const JsonLogSink();
  // Postgres deployments apply pending SQL migrations before serving
  // (additive and idempotent; the image ships them under /app/migrations).
  final database = server.database;
  if (database != null) {
    final dir = Directory('migrations');
    if (dir.existsSync()) {
      final applied = await database.migrate(dir);
      _log.info('migrations', fields: {'applied': applied.length});
    } else {
      _log.warning(
        'migrations directory not found',
        fields: {'cwd': Directory.current.path},
      );
    }
  }
  final dsn = config.sentryDsn;
  if (dsn != null) {
    await Sentry.init((options) {
      options
        ..dsn = dsn
        ..environment = Platform.environment['SENTRY_ENVIRONMENT'] ?? 'prod'
        ..release = 'vaultflow_server@$vfServerVersion';
    });
    server.errorReporter = (error, stackTrace) =>
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    _log.info('sentry enabled');
  }
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final httpServer = await serve(handler, ip, port);
  _log.info('listening', fields: {'address': ip.address, 'port': port});
  var shuttingDown = false;
  Future<void> shutdown(ProcessSignal signal) async {
    if (shuttingDown) return;
    shuttingDown = true;
    final server = globalServerContext();
    final grace = server.config.shutdownGrace;
    _log.info('shutting down', fields: {'signal': signal.name, 'grace': grace});
    // Stop accepting new connections, let in-flight requests finish within
    // the grace period, then cut whatever is left (long SSE streams).
    await httpServer.close();
    final drained = await server.inFlight.drain(grace);
    if (!drained) {
      _log.warning(
        'grace period elapsed; closing remaining connections',
        fields: {'in_flight': server.inFlight.count},
      );
    }
    await httpServer.close(force: true);
    await server.close();
    await Sentry.close();
    _log.info('bye');
    await stdout.flush();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(shutdown);
  ProcessSignal.sigint.watch().listen(shutdown);
  return httpServer;
}
