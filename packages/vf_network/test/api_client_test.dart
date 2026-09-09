import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_network/testing.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  late FakeAdapter adapter;
  late ApiClient client;
  late InMemoryTokenStore store;

  const creds = CredentialsRequest(
    email: 'a@b.c',
    password: 'pw123456',
    deviceName: 'Test',
    platform: 'macos',
  );

  setUp(() {
    adapter = FakeAdapter();
    store = InMemoryTokenStore();
    final dio = DioFactory.create(
      baseUrl: 'https://api.test',
      tokens: store,
      onAuthLost: () {},
    )..httpClientAdapter = adapter;
    client = ApiClient(dio);
  });

  test('register parses AuthTokens', () async {
    adapter.on('POST', '/auth/register', (o) {
      expect((o.data as Map)['email'], 'a@b.c');
      return const FakeResponse(201, {
        'access_token': 'a',
        'refresh_token': 'r',
        'device_id': 'd',
        'user_id': 'u',
        'expires_in': 900,
      });
    });
    final result = await client.register(creds);
    expect(result.getOrThrow().deviceId, 'd');
  });

  test('401 becomes AuthFailure with the server message', () async {
    adapter.on(
      'POST',
      '/auth/login',
      (o) => const FakeResponse(401, {
        'error': {'code': 'unauthorized', 'message': 'Incorrect email'},
      }),
    );
    final result = await client.login(creds);
    expect(result.failureOrNull, isA<AuthFailure>());
    expect(result.failureOrNull!.message, 'Incorrect email');
  });

  test('409 becomes ServerFailure with the wire code', () async {
    adapter.on(
      'POST',
      '/auth/register',
      (o) => const FakeResponse(409, {
        'error': {'code': 'email_taken', 'message': 'taken'},
      }),
    );
    final failure = (await client.register(creds)).failureOrNull;
    expect(failure, isA<ServerFailure>());
    expect((failure! as ServerFailure).statusCode, 409);
    expect((failure as ServerFailure).code, 'email_taken');
  });

  test('connection errors become NetworkFailure', () {
    final failure = ApiClient.mapDioException(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(failure, isA<NetworkFailure>());
  });

  test('me uses the stored token', () async {
    await store.write(
      const AuthTokens(
        accessToken: 'tok',
        refreshToken: 'r',
        deviceId: 'd',
        userId: 'u',
        expiresIn: 900,
      ),
    );
    adapter.on('GET', '/auth/me', (o) {
      expect(o.headers['Authorization'], 'Bearer tok');
      return const FakeResponse(200, {
        'user_id': 'u',
        'email': 'a@b.c',
        'device_id': 'd',
      });
    });
    final me = (await client.me()).getOrThrow();
    expect(me.email, 'a@b.c');
  });

  test('logout maps 204 to Ok', () async {
    adapter.on('POST', '/auth/logout', (o) => const FakeResponse(204));
    final result = await client.logout(
      const RefreshRequest(refreshToken: 'r', deviceId: 'd'),
    );
    expect(result.isOk, isTrue);
  });

  test('push and changes are typed over the sync DTOs', () async {
    adapter
      ..on('POST', '/sync/push', (o) {
        final ops = (o.data as Map)['ops'] as List;
        expect((ops.single as Map)['op'], 'create');
        return const FakeResponse(200, {
          'results': [
            {'client_op_id': 'c1', 'status': 'applied', 'new_version': 1},
          ],
        });
      })
      ..on('GET', '/sync/changes', (o) {
        expect(o.queryParameters['since'], 7);
        expect(o.queryParameters['exclude_device'], 'd');
        return const FakeResponse(200, {
          'changes': <Object?>[],
          'next_cursor': 7,
          'has_more': false,
        });
      });
    final pushed = await client.push(
      const PushRequest(
        deviceId: 'd',
        ops: [
          SyncOpRequest(
            clientOpId: 'c1',
            entityType: EntityType.note,
            entityId: 'n',
            op: SyncOp.create,
            baseVersion: 0,
          ),
        ],
      ),
    );
    expect(pushed.getOrThrow().results.single.newVersion, 1);
    final pulled = await client.changes(since: 7, excludeDeviceId: 'd');
    expect(pulled.getOrThrow().hasMore, isFalse);
  });

  test('createDownloadUrl parses the link and resolves it', () async {
    adapter.on(
      'POST',
      '/documents/doc-1/download-url',
      (_) => const FakeResponse(200, {
        'url': '/documents/doc-1/content?token=abc',
        'expires_at': '2026-09-09T10:00:00.000Z',
      }),
    );
    final result = await client.createDownloadUrl('doc-1');
    final link = result.getOrThrow();
    expect(link.url, '/documents/doc-1/content?token=abc');
    expect(
      client.absolute(link.url).toString(),
      'https://api.test/documents/doc-1/content?token=abc',
    );
  });

  test('syncEvents yields change sequences and ignores pings', () async {
    adapter.on('GET', '/sync/events', (o) {
      expect(o.queryParameters['exclude_device'], 'd');
      return FakeResponse.stream(
        200,
        Stream.fromIterable([
          'retry: 3000\n\n',
          ': ping\n\n',
          'event: change\ndata: {"seq": 4}\n\n',
          'event: change\n',
          'data: {"seq": 9}\n\n',
        ]).map((s) => Uint8List.fromList(s.codeUnits)),
        headers: {'content-type': 'text/event-stream'},
      );
    });
    final seqs = await client.syncEvents(excludeDeviceId: 'd').toList();
    expect(seqs, [4, 9]);
  });

  test('syncEvents surfaces connection errors as failures', () async {
    adapter.on('GET', '/sync/events', (o) {
      throw DioException.connectionError(requestOptions: o, reason: 'down');
    });
    await expectLater(
      client.syncEvents().toList(),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
