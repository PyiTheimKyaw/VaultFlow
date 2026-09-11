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
    this.maxJsonBodyBytes = 1024 * 1024,
    this.maxUploadBytes = 10 * 1024 * 1024 * 1024,
    this.rateLimitPerMinute = 600,
    this.authRateLimitPerMinute = 20,
    this.trustProxy = false,
    this.logFormat = LogFormat.text,
    this.sentryDsn,
    this.metricsToken,
    this.shutdownGrace = const Duration(seconds: 20),
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
      maxJsonBodyBytes: intOr('MAX_JSON_BODY_BYTES', 1024 * 1024),
      maxUploadBytes: intOr('MAX_UPLOAD_BYTES', 10 * 1024 * 1024 * 1024),
      rateLimitPerMinute: intOr('RATE_LIMIT_PER_MINUTE', 600),
      authRateLimitPerMinute: intOr('AUTH_RATE_LIMIT_PER_MINUTE', 20),
      trustProxy: e['TRUST_PROXY'] == 'true',
      logFormat: e['LOG_FORMAT'] == 'json' ? LogFormat.json : LogFormat.text,
      sentryDsn: (e['SENTRY_DSN'] ?? '').isEmpty ? null : e['SENTRY_DSN'],
      metricsToken: (e['METRICS_TOKEN'] ?? '').isEmpty
          ? null
          : e['METRICS_TOKEN'],
      shutdownGrace: Duration(seconds: intOr('SHUTDOWN_GRACE_SECONDS', 20)),
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

  /// Largest accepted JSON request body.
  final int maxJsonBodyBytes;

  /// Largest file an upload session may declare.
  final int maxUploadBytes;

  /// Requests per minute per client (IP, or user once authenticated);
  /// `0` disables limiting.
  final int rateLimitPerMinute;

  /// Stricter budget for `/auth/login` and `/auth/register` per IP.
  final int authRateLimitPerMinute;

  /// Read the client IP from `X-Forwarded-For` (only behind a proxy you
  /// control).
  final bool trustProxy;

  final LogFormat logFormat;

  /// When set, unhandled errors are reported to Sentry.
  final String? sentryDsn;

  /// When set, `GET /metrics` is enabled for callers presenting it as a
  /// bearer token.
  final String? metricsToken;

  /// How long in-flight requests may finish after SIGTERM.
  final Duration shutdownGrace;

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

enum LogFormat { text, json }
