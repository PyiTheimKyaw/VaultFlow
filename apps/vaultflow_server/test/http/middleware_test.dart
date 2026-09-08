import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

import '../helpers.dart';

void main() {
  late ServerContext server;

  setUp(() => server = testContext());

  test('errorHandler maps ApiException and hides unexpected errors', () async {
    final handled = await errorHandler()(
      (_) => throw const ApiException.notFound('gone'),
    )(requestContext(server, 'GET', '/x'));
    expect(handled.statusCode, 404);
    expect(((await decodeJson(handled))['error']! as Map)['message'], 'gone');

    final crashed = await errorHandler()(
      (_) => throw StateError('secret internals'),
    )(requestContext(server, 'GET', '/x'));
    expect(crashed.statusCode, 500);
    final body = await crashed.body();
    expect(body, isNot(contains('secret internals')));
    expect(body, contains('internal'));
  });

  test('requestId echoes an incoming id and generates one otherwise', () async {
    final context = MockRequestContext();
    when(() => context.request).thenReturn(
      Request(
        'GET',
        Uri.parse('http://localhost/x'),
        headers: {'x-request-id': 'abc'},
      ),
    );
    when(() => context.provide<RequestId>(any())).thenReturn(context);
    final echoed = await requestId()((_) => Response())(context);
    expect(echoed.headers['X-Request-Id'], 'abc');

    when(() => context.request)
        .thenReturn(Request('GET', Uri.parse('http://localhost/x')));
    final generated = await requestId()((_) => Response())(context);
    expect(generated.headers['X-Request-Id'], isNotEmpty);
  });

  test('cors answers preflights and stamps allowed origins', () async {
    final middleware = cors(['https://app.example.com']);
    final preflight = await middleware((_) => Response())(
      requestContext(
        server,
        'OPTIONS',
        '/auth/login',
        headers: {'origin': 'https://app.example.com'},
      ),
    );
    expect(preflight.statusCode, 204);
    expect(
      preflight.headers['Access-Control-Allow-Origin'],
      'https://app.example.com',
    );

    final denied = await middleware((_) => Response())(
      requestContext(
        server,
        'GET',
        '/x',
        headers: {'origin': 'https://evil.example'},
      ),
    );
    expect(denied.headers.containsKey('Access-Control-Allow-Origin'), isFalse);
  });

  test('authRequired provides AuthContext for a valid bearer token', () async {
    final tokens = await server.auth.register(
      const CredentialsRequestFixture().value,
    );
    final context = requestContext(
      server,
      'GET',
      '/sync/changes',
      headers: {'authorization': 'Bearer ${tokens.accessToken}'},
    );
    late AuthContext seen;
    when(() => context.provide<AuthContext>(any())).thenAnswer((invocation) {
      seen = (invocation.positionalArguments.first as AuthContext Function())();
      return context;
    });
    final response = await authRequired()((_) => Response())(context);
    expect(response.statusCode, 200);
    expect(seen.userId, tokens.userId);
    expect(seen.deviceId, tokens.deviceId);

    expect(
      () => authRequired()((_) => Response())(
        requestContext(
          server,
          'GET',
          '/sync/changes',
          headers: {'authorization': 'Bearer nope'},
        ),
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
