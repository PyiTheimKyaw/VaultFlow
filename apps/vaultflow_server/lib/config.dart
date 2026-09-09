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
    this.storageBackend = StorageBackend.local,
    this.storageRoot = '.storage',
    this.s3,
    this.uploadSessionTtl = const Duration(hours: 24),
    this.maxChunkSize = 8 * 1024 * 1024,
    this.downloadLinkTtl = const Duration(minutes: 5),
    this.eventsMaxAge = const Duration(minutes: 5),
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
    final backend = switch (e['STORAGE_BACKEND']) {
      's3' => StorageBackend.s3,
      _ => StorageBackend.local,
    };
    return ServerConfig(
      jwtSecret: secret,
      storageBackend: backend,
      storageRoot: e['STORAGE_ROOT'] ?? '.storage',
      s3: backend == StorageBackend.s3
          ? S3Config(
              endpoint: e['S3_ENDPOINT'] ?? 'localhost',
              port: intOr('S3_PORT', 9000),
              useSsl: e['S3_USE_SSL'] == 'true',
              accessKey: e['S3_ACCESS_KEY'] ?? '',
              secretKey: e['S3_SECRET_KEY'] ?? '',
              bucket: e['S3_BUCKET'] ?? 'vaultflow',
              region: e['S3_REGION'],
            )
          : null,
      uploadSessionTtl: Duration(hours: intOr('UPLOAD_SESSION_TTL_HOURS', 24)),
      maxChunkSize: intOr('MAX_CHUNK_SIZE', 8 * 1024 * 1024),
      downloadLinkTtl: Duration(minutes: intOr('DOWNLOAD_LINK_TTL_MINUTES', 5)),
      eventsMaxAge: Duration(minutes: intOr('EVENTS_MAX_AGE_MINUTES', 5)),
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
  final StorageBackend storageBackend;

  /// Directory for [StorageBackend.local].
  final String storageRoot;
  final S3Config? s3;
  final Duration uploadSessionTtl;

  /// Largest chunk the server accepts in one request.
  final int maxChunkSize;

  /// Lifetime of a signed browser download link.
  final Duration downloadLinkTtl;

  /// How long one `/sync/events` connection stays open before the client
  /// must reconnect.
  final Duration eventsMaxAge;

  bool get usesPostgres => databaseUrl != null;
}

enum StorageBackend { local, s3 }

class S3Config {
  const S3Config({
    required this.endpoint,
    required this.port,
    required this.useSsl,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    this.region,
  });

  final String endpoint;
  final int port;
  final bool useSsl;
  final String accessKey;
  final String secretKey;
  final String bucket;
  final String? region;
}
