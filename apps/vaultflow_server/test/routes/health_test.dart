import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext;

void main() {
  group('GET /health', () {
    test('responds with 200 and status ok', () async {
      final context = _MockRequestContext();
      final request = Request.get(Uri.parse('http://localhost/health'));
      when(() => context.request).thenReturn(request);

      final response = route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
    });

    test('rejects non-GET methods', () {
      final context = _MockRequestContext();
      final request = Request.post(Uri.parse('http://localhost/health'));
      when(() => context.request).thenReturn(request);

      final response = route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });
}
