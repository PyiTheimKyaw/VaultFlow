import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:vaultflow_server/vaultflow_server.dart' as server;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/testing.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_sync/vf_sync.dart';

/// The real server `SyncService` behind a fake HTTP adapter, so client tests
/// exercise the actual push/pull semantics. Auth is not enforced: the bearer
/// token names the user and device via [sessions].
class FakeSyncServer {
  FakeSyncServer({FakeClock? clock})
    : clock = clock ?? FakeClock(DateTime.utc(2026, 9, 8, 9)) {
    service = server.SyncService(store: store, clock: this.clock);
    adapter
      ..on('POST', ApiPaths.syncPush, _push)
      ..on('GET', ApiPaths.syncChanges, _changes);
  }

  final adapter = FakeAdapter();
  final store = server.InMemorySyncStore();
  late final server.SyncService service;
  final FakeClock clock;

  /// Access token → (userId, deviceId).
  final Map<String, (String, String)> sessions = {};

  bool offline = false;

  /// Runs while a push is being processed (before the response), to
  /// simulate a local edit racing the in-flight batch.
  Future<void> Function()? onBeforePush;
  int pushes = 0;
  int pulls = 0;

  (String, String) _who(RequestOptions o) {
    final auth = o.headers['Authorization'] as String? ?? '';
    final token = auth.replaceFirst('Bearer ', '');
    return sessions[token] ?? (throw StateError('unknown token $token'));
  }

  Future<FakeResponse> _push(RequestOptions o) async {
    pushes++;
    if (offline) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    final (userId, deviceId) = _who(o);
    await onBeforePush?.call();
    final request = PushRequest.fromJson(
      jsonDecode(jsonEncode(o.data)) as Map<String, Object?>,
    );
    try {
      final response = await service.push(
        userId: userId,
        deviceId: deviceId,
        request: request,
      );
      return FakeResponse(200, response.toJson());
    } on server.ApiException catch (e) {
      return FakeResponse(e.code.httpStatus, e.error.toEnvelope());
    }
  }

  Future<FakeResponse> _changes(RequestOptions o) async {
    pulls++;
    if (offline) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    final (userId, _) = _who(o);
    final q = o.queryParameters;
    final response = await service.changes(
      userId: userId,
      since: int.parse('${q['since']}'),
      limit: int.parse('${q['limit'] ?? 500}'),
      excludeDeviceId: q['exclude_device'] as String?,
    );
    return FakeResponse(200, response.toJson());
  }
}

/// One device: its own database, tokens and engine, talking to [server].
class Device {
  Device._(this.name, this.db, this.engine, this.clock);

  static Future<Device> create(
    FakeSyncServer server, {
    required String name,
    String userId = 'user-1',
    FakeClock? clock,
  }) async {
    final c = clock ?? server.clock;
    final db = openInMemoryDatabase();
    final deviceId = VfId.next();
    final token = 'token-$name';
    server.sessions[token] = (userId, deviceId);
    final tokens = InMemoryTokenStore(
      AuthTokens(
        accessToken: token,
        refreshToken: 'r',
        deviceId: deviceId,
        userId: userId,
        expiresIn: 900,
      ),
    );
    final dio = DioFactory.create(
      baseUrl: 'https://api.test',
      tokens: tokens,
      onAuthLost: () {},
    )..httpClientAdapter = server.adapter;
    final engine = SyncEngine(
      db: db,
      api: ApiClient(dio),
      deviceId: deviceId,
      deviceLabel: name,
      clock: c,
      random: Random(1),
    );
    await engine.recover();
    return Device._(name, db, engine, c);
  }

  final String name;
  final VaultFlowDatabase db;
  final SyncEngine engine;
  final FakeClock clock;

  late final vault = DriftVaultRepository(db);
  late final notes = DriftNotesRepository(db);

  Note newNote(String title, {String body = ''}) => Note(
    id: VfId.next(),
    title: title,
    body: body,
    createdAt: clock.now(),
    updatedAt: clock.now(),
  );

  Future<List<OutboxRow>> outbox() => db.outboxDao.getAll();

  Future<List<NoteRow>> liveNotes() => db.notesDao.getAllLive();

  Future<List<ConflictRow>> conflicts() => db.conflictsDao.getUnresolved();

  Future<void> close() async {
    engine.dispose();
    await db.close();
  }
}

/// Handy 401 for auth-failure tests.
class FakeResponse401 extends FakeResponse {
  const FakeResponse401()
    : super(401, const {
        'error': {'code': 'unauthorized', 'message': 'token invalid'},
      });
}

abstract final class PushRequestFixture {
  static PushRequest single(String deviceId, OutboxRow row) =>
      PushRequest(deviceId: deviceId, ops: [Mappers.outbox(row).toRequest()]);
}

class StreamControllerFixture {
  final _controller = StreamController<int>.broadcast();
  Stream<int> get stream => _controller.stream;
  void add(int value) => _controller.add(value);
}
