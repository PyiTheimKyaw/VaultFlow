import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:vf_core/vf_core.dart';

const _log = Logger('db');

/// Thin wrapper around a postgres [Pool] with a file-based migration runner.
class Database {
  Database(this.pool);

  /// Opens a pool from a `postgres://user:pass@host:port/db?sslmode=...` URL.
  factory Database.fromUrl(String url, {int maxConnections = 8}) {
    final uri = Uri.parse(url);
    final userInfo = uri.userInfo.split(':');
    final sslMode = switch (uri.queryParameters['sslmode']) {
      'require' => SslMode.require,
      'verify-full' => SslMode.verifyFull,
      _ => SslMode.disable,
    };
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isEmpty ? 'postgres' : uri.pathSegments.first,
      username: userInfo.isNotEmpty ? Uri.decodeComponent(userInfo[0]) : null,
      password: userInfo.length > 1 ? Uri.decodeComponent(userInfo[1]) : null,
    );
    return Database(
      Pool<void>.withEndpoints(
        [endpoint],
        settings: PoolSettings(
          maxConnectionCount: maxConnections,
          sslMode: sslMode,
        ),
      ),
    );
  }

  final Pool<void> pool;

  /// Applies every `NNNN_name.sql` in [migrationsDir] that has not been
  /// recorded in `schema_migrations`, in file-name order, each in its own
  /// transaction.
  Future<List<String>> migrate(Directory migrationsDir) async {
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )''');
    final applied = (await pool.execute(
      'SELECT version FROM schema_migrations',
    )).map((r) => r[0]! as String).toSet();
    final files =
        migrationsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final ran = <String>[];
    for (final file in files) {
      final version = p.basenameWithoutExtension(file.path);
      if (applied.contains(version)) continue;
      final sql = await file.readAsString();
      await pool.runTx((tx) async {
        await tx.execute(sql, queryMode: QueryMode.simple);
        await tx.execute(
          Sql.named('INSERT INTO schema_migrations (version) VALUES (@v)'),
          parameters: {'v': version},
        );
      });
      _log.info('applied migration', fields: {'version': version});
      ran.add(version);
    }
    return ran;
  }

  Future<void> close() => pool.close();
}
