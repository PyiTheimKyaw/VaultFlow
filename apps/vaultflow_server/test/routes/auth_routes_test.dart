import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

import '../../routes/auth/login.dart' as login;
import '../../routes/auth/logout.dart' as logout;
import '../../routes/auth/me.dart' as me;
import '../../routes/auth/refresh.dart' as refresh;
import '../../routes/auth/register.dart' as register;
import '../helpers.dart';

void main() {
  late ServerContext server;

  setUp(() => server = testContext());

  Future<Response> call(
    Future<Response> Function(RequestContext) route,
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) async => await errorHandler()(route)(
    requestContext(server, method, path, body: body, headers: headers),
  );

  test('register returns 201 with tokens', () async {
    final response = await call(
      register.onRequest,
      'POST',
      '/auth/register',
      body: credentials(),
    );
    expect(response.statusCode, 201);
    final json = await decodeJson(response);
    expect(json['access_token'], isNotEmpty);
    expect(json['refresh_token'], isNotEmpty);
    expect(json['device_id'], isNotEmpty);
  });

  test('register validates and maps errors to the envelope', () async {
    final bad = await call(
      register.onRequest,
      'POST',
      '/auth/register',
      body: credentials(password: 'x'),
    );
    expect(bad.statusCode, 400);
    final json = await decodeJson(bad);
    final error = json['error']! as Map<String, Object?>;
    expect(error['code'], 'validation_failed');
    expect((error['details']! as Map)['field'], 'password');

    final malformed = await call(
      register.onRequest,
      'POST',
      '/auth/register',
      body: {'email': 'a@b.c'},
    );
    expect(malformed.statusCode, 400);

    final wrongMethod = await call(register.onRequest, 'GET', '/auth/register');
    expect(wrongMethod.statusCode, 405);
  });

  test('login, me, refresh and logout round trip', () async {
    await call(
      register.onRequest,
      'POST',
      '/auth/register',
      body: credentials(),
    );
    final login1 = await call(
      login.onRequest,
      'POST',
      '/auth/login',
      body: credentials(),
    );
    expect(login1.statusCode, 200);
    final tokens = await decodeJson(login1);

    final whoami = await call(
      me.onRequest,
      'GET',
      '/auth/me',
      headers: {'authorization': 'Bearer ${tokens['access_token']}'},
    );
    expect(whoami.statusCode, 200);
    expect((await decodeJson(whoami))['email'], 'me@example.com');

    final noAuth = await call(me.onRequest, 'GET', '/auth/me');
    expect(noAuth.statusCode, 401);
    expect(
      ((await decodeJson(noAuth))['error']! as Map)['code'],
      'unauthorized',
    );

    final refreshed = await call(
      refresh.onRequest,
      'POST',
      '/auth/refresh',
      body: {
        'refresh_token': tokens['refresh_token'],
        'device_id': tokens['device_id'],
      },
    );
    expect(refreshed.statusCode, 200);
    final newTokens = await decodeJson(refreshed);

    // Replaying the old refresh token revokes the family.
    final replay = await call(
      refresh.onRequest,
      'POST',
      '/auth/refresh',
      body: {
        'refresh_token': tokens['refresh_token'],
        'device_id': tokens['device_id'],
      },
    );
    expect(replay.statusCode, 401);
    expect(
      ((await decodeJson(replay))['error']! as Map)['code'],
      'token_revoked',
    );

    final loggedOut = await call(
      logout.onRequest,
      'POST',
      '/auth/logout',
      body: {
        'refresh_token': newTokens['refresh_token'],
        'device_id': newTokens['device_id'],
      },
    );
    expect(loggedOut.statusCode, 204);
  });

  test('wrong password is 401 with a generic message', () async {
    await call(
      register.onRequest,
      'POST',
      '/auth/register',
      body: credentials(),
    );
    final response = await call(
      login.onRequest,
      'POST',
      '/auth/login',
      body: credentials(password: 'not the password'),
    );
    expect(response.statusCode, 401);
    final error = (await decodeJson(response))['error']! as Map;
    expect(error['message'], 'Incorrect email or password');
  });
}
