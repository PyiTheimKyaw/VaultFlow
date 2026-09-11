import 'package:vaultflow_server/auth/auth_service.dart';
import 'package:vaultflow_server/auth/auth_store.dart';
import 'package:vaultflow_server/auth/password_hasher.dart';
import 'package:vaultflow_server/auth/postgres_auth_store.dart';
import 'package:vaultflow_server/auth/token_service.dart';
import 'package:vaultflow_server/config.dart';
import 'package:vaultflow_server/db/database.dart';
import 'package:vaultflow_server/http/in_flight.dart';
import 'package:vaultflow_server/http/metrics.dart';
import 'package:vaultflow_server/http/rate_limiter.dart';
import 'package:vaultflow_server/storage/s3_storage.dart';
import 'package:vaultflow_server/storage/storage_adapter.dart';
import 'package:vaultflow_server/sync/postgres_sync_store.dart';
import 'package:vaultflow_server/sync/sync_service.dart';
import 'package:vaultflow_server/sync/sync_store.dart';
import 'package:vaultflow_server/transfer/content_service.dart';
import 'package:vaultflow_server/transfer/postgres_upload_store.dart';
import 'package:vaultflow_server/transfer/upload_service.dart';
import 'package:vaultflow_server/transfer/upload_store.dart';
import 'package:vf_core/vf_core.dart';

const _log = Logger('server');

/// Composition root: everything routes need, built once per process.
class ServerContext {
  ServerContext({
    required this.config,
    required this.store,
    required this.hasher,
    required this.tokens,
    required this.auth,
    required this.syncStore,
    required this.sync,
    required this.uploadStore,
    required this.storage,
    required this.uploads,
    required this.content,
    this.clock = const SystemClock(),
    this.database,
    Metrics? metrics,
    RateLimiter? limiter,
    RateLimiter? authLimiter,
  }) : metrics = metrics ?? Metrics(clock: clock),
       limiter =
           limiter ??
           RateLimiter(limit: config.rateLimitPerMinute, clock: clock),
       authLimiter =
           authLimiter ??
           RateLimiter(limit: config.authRateLimitPerMinute, clock: clock);

  factory ServerContext.create(
    ServerConfig config, {
    Clock clock = const SystemClock(),
  }) {
    final Database? database;
    final AuthStore store;
    final SyncStore syncStore;
    final UploadStore uploadStore;
    if (config.usesPostgres) {
      database = Database.fromUrl(config.databaseUrl!);
      store = PostgresAuthStore(database.pool);
      syncStore = PostgresSyncStore(database.pool);
      uploadStore = PostgresUploadStore(database.pool);
      _log.info('using postgres store');
    } else {
      database = null;
      store = InMemoryAuthStore();
      syncStore = InMemorySyncStore();
      uploadStore = InMemoryUploadStore();
      _log.warning('DATABASE_URL not set: using in-memory store (dev only)');
    }
    final storage = switch (config.storageBackend) {
      StorageBackend.s3 => S3Storage(config.s3!),
      StorageBackend.local => LocalFsStorage(config.storageRoot),
    };
    _log.info(
      'object storage',
      fields: {
        'backend': config.storageBackend.name,
        'root': config.storageRoot,
      },
    );
    final uploads = UploadService(
      store: uploadStore,
      storage: storage,
      sync: syncStore,
      sessionTtl: config.uploadSessionTtl,
      maxChunkSize: config.maxChunkSize,
      maxUploadBytes: config.maxUploadBytes,
      clock: clock,
    );
    final hasher = PasswordHasher(
      memoryKiB: config.argon2MemoryKiB,
      iterations: config.argon2Iterations,
    );
    final tokens = TokenService(
      secret: config.jwtSecret,
      accessTokenTtl: config.accessTokenTtl,
      clock: clock,
    );
    return ServerContext(
      config: config,
      database: database,
      store: store,
      hasher: hasher,
      tokens: tokens,
      auth: AuthService(
        store: store,
        hasher: hasher,
        tokens: tokens,
        refreshTokenTtl: config.refreshTokenTtl,
        clock: clock,
      ),
      syncStore: syncStore,
      sync: SyncService(
        store: syncStore,
        clock: clock,
        ownsBlob: uploads.ownsBlob,
      ),
      uploadStore: uploadStore,
      storage: storage,
      uploads: uploads,
      content: ContentService(
        sync: syncStore,
        uploads: uploadStore,
        storage: storage,
      ),
    );
  }

  final ServerConfig config;
  final Database? database;
  final AuthStore store;
  final PasswordHasher hasher;
  final TokenService tokens;
  final AuthService auth;
  final SyncStore syncStore;
  final SyncService sync;
  final UploadStore uploadStore;
  final StorageAdapter storage;
  final UploadService uploads;
  final ContentService content;
  final Clock clock;
  final Metrics metrics;
  final InFlightTracker inFlight = InFlightTracker();

  /// Where unhandled errors go besides the log (Sentry when configured).
  void Function(Object error, StackTrace stackTrace)? errorReporter;

  void reportError(Object error, StackTrace stackTrace) =>
      errorReporter?.call(error, stackTrace);

  /// Releases the database pool; called on graceful shutdown.
  Future<void> close() async {
    await database?.close();
  }

  final RateLimiter limiter;
  final RateLimiter authLimiter;
}

ServerContext? _global;

/// Process-wide context used by the route middleware, built lazily from the
/// environment. Tests call [installServerContext] to inject their own.
ServerContext globalServerContext() =>
    _global ??= ServerContext.create(ServerConfig.fromEnvironment());

void installServerContext(ServerContext context) => _global = context;
