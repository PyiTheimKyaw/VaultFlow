import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

import '../../routes/sync/changes.dart' as changes;
import '../../routes/sync/push.dart' as push;
import '../helpers.dart';

void main() {
  late ServerContext server;
  late AuthTokens tokens;

  setUp(() async {
    server = testContext();
    tokens = await server.auth.register(
      const CredentialsRequestFixture().value,
    );
  });

  /// Runs the route behind the same auth middleware the real app uses.
  Future<Response> call(
    Future<Response> Function(RequestContext) route,
    String method,
    String path, {
    Object? body,
    String? bearer,
  }) async {
    final context = requestContext(
      server,
      method,
      path,
      body: body,
      headers: {'authorization': 'Bearer ${bearer ?? tokens.accessToken}'},
    );
    when(() => context.provide<AuthContext>(any())).thenAnswer((invocation) {
      final auth =
          (invocation.positionalArguments.first as AuthContext Function())();
      when(() => context.read<AuthContext>()).thenReturn(auth);
      return context;
    });
    return await errorHandler()(authRequired()(route))(context);
  }

  test('push applies ops and changes returns them to other devices', () async {
    final noteId = VfId.next();
    final response = await call(
      push.onRequest,
      'POST',
      '/sync/push',
      body: {
        'device_id': tokens.deviceId,
        'ops': [
          {
            'client_op_id': 'op-1',
            'entity_type': 'note',
            'entity_id': noteId,
            'op': 'create',
            'base_version': 0,
            'payload': {'title': 'T', 'body': 'B'},
          },
        ],
      },
    );
    expect(response.statusCode, 200);
    final result = PushResponse.fromJson(await decodeJson(response))
        .results
        .single;
    expect(result.status, SyncOpStatus.applied);
    expect(result.newVersion, 1);

    final own = await call(
      changes.onRequest,
      'GET',
      '/sync/changes?since=0&exclude_device=${tokens.deviceId}',
    );
    expect(ChangesResponse.fromJson(await decodeJson(own)).changes, isEmpty);

    final all = await call(
      changes.onRequest,
      'GET',
      '/sync/changes?since=0&limit=10',
    );
    final feed = ChangesResponse.fromJson(await decodeJson(all));
    expect(feed.changes.single.entityId, noteId);
    expect(feed.nextCursor, 1);
  });

  test('push rejects a device_id that does not match the token', () async {
    final response = await call(
      push.onRequest,
      'POST',
      '/sync/push',
      body: {'device_id': 'someone-else', 'ops': <Object?>[]},
    );
    expect(response.statusCode, 403);
  });

  test('sync routes require a valid bearer token', () async {
    final response = await call(
      changes.onRequest,
      'GET',
      '/sync/changes',
      bearer: 'nope',
    );
    expect(response.statusCode, 401);
    final bad = await call(changes.onRequest, 'GET', '/sync/changes?since=-1');
    expect(bad.statusCode, 400);
  });
}
