import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_network/testing.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';

AuthTokens _tokens(String access, String refresh) => AuthTokens(
  accessToken: access,
  refreshToken: refresh,
  deviceId: 'dev',
  userId: 'user',
  expiresIn: 900,
);

void main() {
  late FakeAdapter adapter;
  late InMemoryTokenStore store;
  late Dio dio;
  var authLost = 0;

  setUp(() {
    adapter = FakeAdapter();
    store = InMemoryTokenStore(_tokens('old', 'r1'));
    authLost = 0;
    dio = DioFactory.create(
      baseUrl: 'https://api.test',
      tokens: store,
      onAuthLost: () => authLost++,
    )..httpClientAdapter = adapter;
  });

  AuthInterceptor interceptor() =>
      dio.interceptors.whereType<AuthInterceptor>().single;

  test('attaches the bearer token and protocol header', () async {
    adapter.on('GET', '/auth/me', (o) {
      expect(o.headers['Authorization'], 'Bearer old');
      expect(o.headers[ApiPaths.protocolHeader], '$vfProtocolVersion');
      return const FakeResponse(200, {'ok': true});
    });
    final response = await dio.get<Map<String, Object?>>('/auth/me');
    expect(response.data, {'ok': true});
  });

  test('three concurrent 401s trigger exactly one refresh', () async {
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    adapter
      ..on('POST', '/auth/refresh', (o) async {
        expect(o.headers.containsKey('Authorization'), isFalse);
        refreshStarted.complete();
        await releaseRefresh.future;
        return FakeResponse(200, _tokens('new', 'r2').toJson());
      })
      ..on('GET', '/sync/changes', (o) {
        final token = o.headers['Authorization'];
        return token == 'Bearer new'
            ? const FakeResponse(200, {'changes': <Object?>[]})
            : const FakeResponse(401, {
                'error': {'code': 'token_expired', 'message': 'expired'},
              });
      });

    final futures = List<Future<Response<Map<String, Object?>>>>.generate(
      3,
      (_) => dio.get<Map<String, Object?>>('/sync/changes'),
    );
    await refreshStarted.future;
    releaseRefresh.complete();
    final responses = await Future.wait(futures);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(interceptor().refreshCount, 1);
    expect((await store.read())!.accessToken, 'new');
    expect(authLost, 0);
    final syncCalls = adapter.calls.where((c) => c.path == '/sync/changes');
    // 3 original 401s + 3 replays.
    expect(syncCalls.length, 6);
  });

  test('failed refresh clears tokens and reports auth lost once', () async {
    adapter
      ..on(
        'POST',
        '/auth/refresh',
        (o) => const FakeResponse(401, {
          'error': {'code': 'token_revoked', 'message': 'revoked'},
        }),
      )
      ..on(
        'GET',
        '/sync/changes',
        (o) => const FakeResponse(401, {
          'error': {'code': 'token_expired', 'message': 'expired'},
        }),
      );
    await expectLater(
      dio.get<Object?>('/sync/changes'),
      throwsA(isA<DioException>()),
    );
    expect(await store.read(), isNull);
    expect(authLost, 1);
    expect(interceptor().refreshCount, 1);
  });

  test('requests marked skipAuth never carry or refresh tokens', () async {
    adapter.on('POST', '/auth/login', (o) {
      expect(o.headers.containsKey('Authorization'), isFalse);
      return const FakeResponse(401, {
        'error': {'code': 'unauthorized', 'message': 'bad creds'},
      });
    });
    await expectLater(
      dio.post<Object?>(
        '/auth/login',
        options: Options(extra: {skipAuthExtra: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(interceptor().refreshCount, 0);
    expect(authLost, 0);
  });

  test('a 401 after a replay is not retried again', () async {
    adapter
      ..on(
        'POST',
        '/auth/refresh',
        (o) => FakeResponse(200, _tokens('new', 'r2').toJson()),
      )
      ..on(
        'GET',
        '/sync/changes',
        (o) => const FakeResponse(401, {
          'error': {'code': 'unauthorized', 'message': 'still no'},
        }),
      );
    await expectLater(
      dio.get<Object?>('/sync/changes'),
      throwsA(isA<DioException>()),
    );
    expect(interceptor().refreshCount, 1);
    expect(adapter.calls.where((c) => c.path == '/sync/changes').length, 2);
  });
}
