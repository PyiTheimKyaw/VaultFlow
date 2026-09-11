import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

import '../../routes/metrics.dart' as metrics_route;
import '../../routes/sync/changes.dart' as changes;
import '../../routes/uploads/index.dart' as create_upload;
import '../helpers.dart';

void main() {
  group('RateLimiter', () {
    test('allows up to the limit per window, then reports retry seconds', () {
      final clock = FakeClock(DateTime.utc(2026, 9, 11, 10));
      final limiter = RateLimiter(limit: 3, clock: clock);
      expect(limiter.hit('a'), isNull);
      expect(limiter.hit('a'), isNull);
      expect(limiter.hit('a'), isNull);
      expect(limiter.remaining('a'), 0);
      clock.advance(const Duration(seconds: 10));
      expect(limiter.hit('a'), 50);
      expect(limiter.hit('b'), isNull, reason: 'keys are independent');
      clock.advance(const Duration(seconds: 51));
      expect(limiter.hit('a'), isNull, reason: 'window rolled over');
      expect(limiter.remaining('a'), 2);
    });

    test('limit 0 disables', () {
      final limiter = RateLimiter(limit: 0);
      expect(limiter.enabled, isFalse);
      for (var i = 0; i < 1000; i++) {
        expect(limiter.hit('x'), isNull);
      }
    });
  });

  group('middleware', () {
    late ServerContext server;
    late FakeClock clock;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 9, 11, 10));
      server = testContext(clock: clock);
    });

    RequestContext ctx(
      String method,
      String path, {
      Object? body,
      List<int>? raw,
      Map<String, String> headers = const {},
    }) {
      final context = MockRequestContext();
      final request = Request(
        method,
        Uri.parse('http://localhost$path'),
        body: raw ?? (body == null ? null : jsonEncode(body)),
        headers: {
          if (body != null) 'content-type': 'application/json',
          ...headers,
        },
      );
      when(() => context.request).thenReturn(request);
      when(() => context.read<ServerContext>()).thenReturn(server);
      when(() => context.provide<AuthContext>(any())).thenAnswer((inv) {
        final auth =
            (inv.positionalArguments.first as AuthContext Function())();
        when(() => context.read<AuthContext>()).thenReturn(auth);
        return context;
      });
      return context;
    }

    Response ok(RequestContext _) => Response(body: 'ok');

    test(
      'rate limit answers 429 with Retry-After and skips preflights',
      () async {
        final limiter = RateLimiter(limit: 2, clock: clock);
        final handler = errorHandler()(
          rateLimit(limiter, keyFor: (_) => 'k')(ok),
        );
        final first = await handler(ctx('GET', '/x'));
        expect(first.headers['X-RateLimit-Remaining'], '1');
        await handler(ctx('GET', '/x'));
        final blocked = await handler(ctx('GET', '/x'));
        expect(blocked.statusCode, 429);
        expect(blocked.headers['Retry-After'], '60');
        expect(
          (await decodeJson(blocked))['error'],
          isA<Map<String, Object?>>(),
        );
        final preflight = await handler(ctx('OPTIONS', '/x'));
        expect(preflight.statusCode, 200);
      },
    );

    test('userOrClientKey prefers the authenticated user', () async {
      final tokens = await server.auth.register(
        const CredentialsRequestFixture().value,
      );
      expect(
        userOrClientKey(
          ctx(
            'GET',
            '/x',
            headers: {'authorization': 'Bearer ${tokens.accessToken}'},
          ),
          trustProxy: false,
        ),
        'user:${tokens.userId}',
      );
      expect(
        userOrClientKey(
          ctx(
            'GET',
            '/x',
            headers: {'x-forwarded-for': '203.0.113.9, 10.0.0.1'},
          ),
          trustProxy: true,
        ),
        'ip:203.0.113.9',
      );
      expect(
        userOrClientKey(
          ctx('GET', '/x', headers: {'x-forwarded-for': '203.0.113.9'}),
          trustProxy: false,
        ),
        'ip:unknown',
        reason: 'forwarded headers are ignored unless the proxy is trusted',
      );
    });

    test('security headers are added and Cache-Control is kept', () async {
      final handler = securityHeaders()(ok);
      final r = await handler(ctx('GET', '/x'));
      expect(r.headers['X-Content-Type-Options'], 'nosniff');
      expect(r.headers['X-Frame-Options'], 'DENY');
      expect(r.headers['Cache-Control'], 'no-store');
      final kept = await securityHeaders()(
        (_) => Response(headers: {'Cache-Control': 'private, max-age=0'}),
      )(ctx('GET', '/x'));
      expect(kept.headers['Cache-Control'], 'private, max-age=0');
    });

    test('JSON bodies over the limit are refused before parsing', () async {
      server = ServerContextFixture.withConfig(
        const ServerConfig(jwtSecret: 'test-secret', maxJsonBodyBytes: 64),
        clock: clock,
      );
      final big = {'email': 'x' * 100};
      await expectLater(
        () => readJsonObject(ctx('POST', '/auth/login', body: big)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.payloadTooLarge,
          ),
        ),
      );
      // Streamed without content-length: still bounded while reading.
      final context = MockRequestContext();
      final request = Request(
        'POST',
        Uri.parse('http://localhost/auth/login'),
        body: Stream.fromIterable([utf8.encode(jsonEncode(big))]),
      );
      when(() => context.request).thenReturn(request);
      when(() => context.read<ServerContext>()).thenReturn(server);
      await expectLater(
        () => readJsonObject(context),
        throwsA(isA<ApiException>()),
      );
      expect(await readJsonObject(ctx('POST', '/auth/login', body: {'a': 1})), {
        'a': 1,
      });
    });

    test('declared upload size is capped', () async {
      server = ServerContextFixture.withConfig(
        const ServerConfig(jwtSecret: 'test-secret', maxUploadBytes: 1000),
        clock: clock,
      );
      final tokens = await server.auth.register(
        const CredentialsRequestFixture().value,
      );
      final handler = errorHandler()(authRequired()(create_upload.onRequest));
      final r = await handler(
        ctx(
          'POST',
          '/uploads',
          body: {
            'document_id': VfId.next(),
            'total_bytes': 1001,
            'sha256': 'a' * 64,
            'mime_type': 'text/plain',
            'chunk_size': 100,
          },
          headers: {'authorization': 'Bearer ${tokens.accessToken}'},
        ),
      );
      expect(r.statusCode, 413);
    });

    test('changes limit is clamped to 500', () async {
      final tokens = await server.auth.register(
        const CredentialsRequestFixture().value,
      );
      final handler = errorHandler()(authRequired()(changes.onRequest));
      final r = await handler(
        ctx(
          'GET',
          '/sync/changes?since=0&limit=999999',
          headers: {'authorization': 'Bearer ${tokens.accessToken}'},
        ),
      );
      expect(r.statusCode, 200);
    });

    test('metrics route needs the configured token', () async {
      final handler = errorHandler()(metrics_route.onRequest);
      expect((await handler(ctx('GET', '/metrics'))).statusCode, 404);

      server = ServerContextFixture.withConfig(
        const ServerConfig(jwtSecret: 'test-secret', metricsToken: 'm3trics'),
        clock: clock,
      );
      expect((await handler(ctx('GET', '/metrics'))).statusCode, 401);
      server.metrics
        ..recordRequest('GET', '/health', 200, const Duration(milliseconds: 3))
        ..increment('sync_ops_applied', 4);
      final r = await handler(
        ctx('GET', '/metrics', headers: {'authorization': 'Bearer m3trics'}),
      );
      expect(r.statusCode, 200);
      final text = await r.body();
      expect(
        text,
        contains(
          'vaultflow_http_requests_total{method="GET",route="/health",'
          'status="200"} 1',
        ),
      );
      expect(text, contains('vaultflow_sync_ops_applied_total 4'));
    });

    test('recordMetrics normalises ids and counts failures as 500', () async {
      final m = server.metrics;
      final handler = recordMetrics(m)(ok);
      final id = VfId.next();
      await handler(ctx('PUT', '/uploads/$id/chunks/7'));
      expect(m.requests.keys, contains('PUT|/uploads/{id}/chunks/{n}|200'));
      final failing = recordMetrics(m)((_) => throw StateError('x'));
      await expectLater(() => failing(ctx('GET', '/boom')), throwsStateError);
      expect(m.requests['GET|/boom|500'], 1);
    });
  });

  group('LocalFsStorage', () {
    test('keys and upload ids cannot escape the root', () async {
      final root = Directory.systemTemp.createTempSync('vf_traversal_');
      addTearDown(() => root.delete(recursive: true));
      final storage = LocalFsStorage(root.path);
      await storage.putPart('../../escape', 0, [1, 2, 3]);
      await storage.assemble('../../escape', 1, '../../../etc/passwd');
      final written = root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .toList();
      expect(written, isNotEmpty);
      for (final path in written) {
        expect(path.startsWith(root.path), isTrue, reason: path);
      }
      expect(await storage.sizeOf('../../../etc/passwd'), 3);
      expect(File('/etc/passwd').readAsBytesSync(), isNot([1, 2, 3]));
    });
  });

  group('InFlightTracker', () {
    test('counts handlers and streamed bodies until they finish', () async {
      final tracker = InFlightTracker();
      final gate = Completer<void>();
      final handler = trackInFlight(tracker)((_) async {
        await gate.future;
        return Response(body: 'done');
      });
      final context = MockRequestContext();
      when(() => context.request)
          .thenReturn(Request('GET', Uri.parse('http://localhost/x')));
      final pending = handler(context);
      await Future<void>.delayed(Duration.zero);
      expect(tracker.count, 1);
      final drain = tracker.drain(const Duration(seconds: 5));
      gate.complete();
      final response = await pending;
      expect(tracker.count, 1, reason: 'body not consumed yet');
      expect(await response.body(), 'done');
      expect(tracker.count, 0);
      expect(await drain, isTrue);
    });

    test('drain gives up after the timeout', () async {
      final tracker = InFlightTracker();
      final handler = trackInFlight(tracker)(
        (_) async =>
            Response.stream(body: StreamController<List<int>>().stream),
      );
      final context = MockRequestContext();
      when(() => context.request)
          .thenReturn(Request('GET', Uri.parse('http://localhost/events')));
      final response = await handler(context);
      unawaited(response.bytes().drain<void>());
      expect(tracker.count, 1);
      expect(await tracker.drain(const Duration(milliseconds: 50)), isFalse);
    });
  });
}
