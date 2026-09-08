import 'dart:io';

/// Server configuration read from the environment (see `.env.example`).
class ServerConfig {
  const ServerConfig({
    required this.jwtSecret,
    this.databaseUrl,
    this.accessTokenTtl = const Duration(minutes: 15),
    this.refreshTokenTtl = const Duration(days: 30),
    this.argon2MemoryKiB = 19456,
    this.argon2Iterations = 2,
    this.corsAllowedOrigins = const ['*'],
    this.port = 8080,
  });

  factory ServerConfig.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    int intOr(String key, int fallback) =>
        int.tryParse(e[key] ?? '') ?? fallback;
    final secret = e['JWT_SECRET'] ?? '';
    if (secret.isEmpty) {
      throw StateError('JWT_SECRET must be set');
    }
    if (secret == 'change-me-in-production' && e['VAULTFLOW_ENV'] == 'prod') {
      throw StateError('Refusing to start in prod with the default JWT_SECRET');
    }
    final origins = (e['CORS_ALLOWED_ORIGINS'] ?? '*')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return ServerConfig(
      jwtSecret: secret,
      databaseUrl: (e['DATABASE_URL'] ?? '').isEmpty ? null : e['DATABASE_URL'],
      accessTokenTtl: Duration(minutes: intOr('ACCESS_TOKEN_TTL_MINUTES', 15)),
      refreshTokenTtl: Duration(days: intOr('REFRESH_TOKEN_TTL_DAYS', 30)),
      argon2MemoryKiB: intOr('ARGON2_MEMORY_KIB', 19456),
      argon2Iterations: intOr('ARGON2_ITERATIONS', 2),
      corsAllowedOrigins: origins,
      port: intOr('PORT', 8080),
    );
  }

  /// `null` runs the server on the in-memory store (development and tests).
  final String? databaseUrl;
  final String jwtSecret;
  final Duration accessTokenTtl;
  final Duration refreshTokenTtl;
  final int argon2MemoryKiB;
  final int argon2Iterations;
  final List<String> corsAllowedOrigins;
  final int port;

  bool get usesPostgres => databaseUrl != null;
}
