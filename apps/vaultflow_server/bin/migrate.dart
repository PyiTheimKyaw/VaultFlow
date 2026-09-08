import 'dart:io';

import 'package:vaultflow_server/vaultflow_server.dart';

/// Applies pending SQL migrations to `DATABASE_URL`.
///
///     dart run bin/migrate.dart
Future<void> main() async {
  final url = Platform.environment['DATABASE_URL'];
  if (url == null || url.isEmpty) {
    stderr.writeln('DATABASE_URL is not set');
    exitCode = 2;
    return;
  }
  final db = Database.fromUrl(url);
  try {
    final ran = await db.migrate(Directory('migrations'));
    stdout.writeln(
      ran.isEmpty ? 'database is up to date' : 'applied: ${ran.join(', ')}',
    );
  } finally {
    await db.close();
  }
}
