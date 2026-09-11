import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

class MockRequestContext extends Mock implements RequestContext;

/// An in-memory [ServerContext] with cheap Argon2id parameters.
ServerContext testContext({FakeClock? clock}) =>
    ServerContextFixture.withConfig(
      const ServerConfig(jwtSecret: 'test-secret'),
      clock: clock,
    );

/// Builds an in-memory [ServerContext] for any [ServerConfig].
abstract final class ServerContextFixture {
  static ServerContext withConfig(ServerConfig config, {FakeClock? clock}) {
    return _build(config, clock);
  }
}

ServerContext _build(ServerConfig config, FakeClock? clock) {
  final c = clock ?? FakeClock(DateTime.utc(2026, 9, 6, 12));
  final store = InMemoryAuthStore();
  final hasher = PasswordHasher(memoryKiB: 256, iterations: 1);
  final tokens = TokenService(
    secret: 'test-secret',
    accessTokenTtl: const Duration(minutes: 15),
    clock: c,
  );
  final syncStore = InMemorySyncStore();
  final uploadStore = InMemoryUploadStore();
  final storage = LocalFsStorage(
    Directory.systemTemp.createTempSync('vf_storage_').path,
  );
  final uploads = UploadService(
    store: uploadStore,
    storage: storage,
    sync: syncStore,
    clock: c,
    maxChunkSize: config.maxChunkSize,
    maxUploadBytes: config.maxUploadBytes,
  );
  return ServerContext(
    config: config,
    syncStore: syncStore,
    sync: SyncService(store: syncStore, clock: c, ownsBlob: uploads.ownsBlob),
    uploadStore: uploadStore,
    storage: storage,
    uploads: uploads,
    content: ContentService(
      sync: syncStore,
      uploads: uploadStore,
      storage: storage,
    ),
    store: store,
    hasher: hasher,
    tokens: tokens,
    clock: c,
    auth: AuthService(
      store: store,
      hasher: hasher,
      tokens: tokens,
      refreshTokenTtl: const Duration(days: 30),
      clock: c,
    ),
  );
}

/// Builds a mocked [RequestContext] for [method] [path] with a JSON [body].
RequestContext requestContext(
  ServerContext server,
  String method,
  String path, {
  Object? body,
  Map<String, String> headers = const {},
}) {
  final context = MockRequestContext();
  final request = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body == null ? null : jsonEncode(body),
    headers: {if (body != null) 'content-type': 'application/json', ...headers},
  );
  when(() => context.request).thenReturn(request);
  when(() => context.read<ServerContext>()).thenReturn(server);
  return context;
}

Map<String, Object?> credentials({
  String email = 'me@example.com',
  String password = 'correct horse',
  String platform = 'macos',
  String? deviceId,
}) => {
  'email': email,
  'password': password,
  'device_name': 'Test Mac',
  'platform': platform,
  'device_id': ?deviceId,
};

/// Default request used by middleware tests.
class CredentialsRequestFixture {
  const CredentialsRequestFixture();

  CredentialsRequest get value => const CredentialsRequest(
    email: 'me@example.com',
    password: 'correct horse',
    deviceName: 'Mac',
    platform: 'macos',
  );
}
