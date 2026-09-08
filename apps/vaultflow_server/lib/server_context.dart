import 'package:vaultflow_server/auth/auth_service.dart';
import 'package:vaultflow_server/auth/auth_store.dart';
import 'package:vaultflow_server/auth/password_hasher.dart';
import 'package:vaultflow_server/auth/postgres_auth_store.dart';
import 'package:vaultflow_server/auth/token_service.dart';
import 'package:vaultflow_server/config.dart';
import 'package:vaultflow_server/db/database.dart';
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
    this.database,
  });

  factory ServerContext.create(
    ServerConfig config, {
    Clock clock = const SystemClock(),
  }) {
    final Database? database;
    final AuthStore store;
    if (config.usesPostgres) {
      database = Database.fromUrl(config.databaseUrl!);
      store = PostgresAuthStore(database.pool);
      _log.info('using postgres store');
    } else {
      database = null;
      store = InMemoryAuthStore();
      _log.warning('DATABASE_URL not set: using in-memory store (dev only)');
    }
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
    );
  }

  final ServerConfig config;
  final Database? database;
  final AuthStore store;
  final PasswordHasher hasher;
  final TokenService tokens;
  final AuthService auth;
}

ServerContext? _global;

/// Process-wide context used by the route middleware, built lazily from the
/// environment. Tests call [installServerContext] to inject their own.
ServerContext globalServerContext() =>
    _global ??= ServerContext.create(ServerConfig.fromEnvironment());

void installServerContext(ServerContext context) => _global = context;
