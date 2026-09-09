// Route files under `[id]` cannot be imported with a simpler path.
// ignore_for_file: simple_directive_paths
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

import '../../routes/documents/[id]/content.dart' as content;
import '../../routes/uploads/[id]/chunks/[n].dart' as chunk;
import '../../routes/uploads/[id]/complete.dart' as complete;
import '../../routes/uploads/[id]/index.dart' as status;
import '../../routes/uploads/index.dart' as create;
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

  RequestContext ctx(
    String method,
    String path, {
    Object? body,
    List<int>? raw,
    Map<String, String> headers = const {},
  }) {
    final context = MockRequestContext();
    final request = raw != null
        ? Request(
            method,
            Uri.parse('http://localhost$path'),
            body: raw,
            headers: {
              'authorization': 'Bearer ${tokens.accessToken}',
              'content-length': '${raw.length}',
              ...headers,
            },
          )
        : Request(
            method,
            Uri.parse('http://localhost$path'),
            body: body == null ? null : jsonEncode(body),
            headers: {
              'authorization': 'Bearer ${tokens.accessToken}',
              if (body != null) 'content-type': 'application/json',
              ...headers,
            },
          );
    when(() => context.request).thenReturn(request);
    when(() => context.read<ServerContext>()).thenReturn(server);
    when(() => context.provide<AuthContext>(any())).thenAnswer((invocation) {
      final auth =
          (invocation.positionalArguments.first as AuthContext Function())();
      when(() => context.read<AuthContext>()).thenReturn(auth);
      return context;
    });
    return context;
  }

  Handler guard(Handler h) => errorHandler()(authRequired()(h));

  test('full upload over the routes, then a ranged download', () async {
    final docId = VfId.next();
    final bytes = List<int>.generate(40, (i) => 255 - i);
    final sha = UploadService.hashOf(bytes);
    // The document must exist server-side for the content route.
    final now = DateTime.utc(2026).toIso8601String();
    await server.syncStore.upsert(
      tokens.userId,
      StoredEntity(
        type: EntityType.document,
        id: docId,
        version: 1,
        snapshot: {
          'id': docId,
          'name': 'x.bin',
          'mime_type': 'application/octet-stream',
          'size_bytes': 40,
          'sha256': sha,
          'version': 1,
          'created_at': now,
          'updated_at': now,
        },
      ),
    );

    final created = await guard(create.onRequest)(
      ctx(
        'POST',
        '/uploads',
        body: {
          'document_id': docId,
          'total_bytes': 40,
          'sha256': sha,
          'mime_type': 'application/octet-stream',
          'chunk_size': 16,
        },
      ),
    );
    expect(created.statusCode, 201);
    final uploadId = (await decodeJson(created))['upload_id']! as String;

    for (var i = 0; i < 3; i++) {
      final part = bytes.sublist(i * 16, (i + 1) * 16 > 40 ? 40 : (i + 1) * 16);
      final res = await guard((c) => chunk.onRequest(c, uploadId, '$i'))(
        ctx(
          'PUT',
          '/uploads/$uploadId/chunks/$i',
          raw: part,
          headers: {'x-chunk-sha256': UploadService.hashOf(part)},
        ),
      );
      expect(res.statusCode, 200, reason: await res.body());
    }
    final st = await guard((c) => status.onRequest(c, uploadId))(
      ctx('GET', '/uploads/$uploadId'),
    );
    expect((await decodeJson(st))['received_chunks'], [0, 1, 2]);

    final done = await guard((c) => complete.onRequest(c, uploadId))(
      ctx('POST', '/uploads/$uploadId/complete'),
    );
    expect(done.statusCode, 200);
    expect((await decodeJson(done))['version'], 2);

    final whole = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', '/documents/$docId/content'),
    );
    expect(whole.statusCode, 200);
    expect(whole.headers['ETag'], '"$sha"');
    expect(whole.headers['Accept-Ranges'], 'bytes');
    expect(
      await whole.bytes().fold<List<int>>([], (a, b) => a..addAll(b)),
      bytes,
    );

    final partial = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', '/documents/$docId/content', headers: {'range': 'bytes=30-'}),
    );
    expect(partial.statusCode, 206);
    expect(partial.headers['Content-Range'], 'bytes 30-39/40');
    expect(partial.headers['Content-Length'], '10');
    expect(
      await partial.bytes().fold<List<int>>([], (a, b) => a..addAll(b)),
      bytes.sublist(30),
    );

    final bad = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', '/documents/$docId/content', headers: {'range': 'bytes=40-'}),
    );
    expect(bad.statusCode, 416);
  });

  test(
    'oversized chunks are refused with 413 and bad indexes with 400',
    () async {
      final docId = VfId.next();
      final big = List<int>.filled(server.config.maxChunkSize + 1, 1);
      final created = await guard(create.onRequest)(
        ctx(
          'POST',
          '/uploads',
          body: {
            'document_id': docId,
            'total_bytes': big.length,
            'sha256': UploadService.hashOf(big),
            'mime_type': 'x/y',
            'chunk_size': 1024,
          },
        ),
      );
      final uploadId = (await decodeJson(created))['upload_id']! as String;
      final tooBig = await guard((c) => chunk.onRequest(c, uploadId, '0'))(
        ctx('PUT', '/uploads/$uploadId/chunks/0', raw: big),
      );
      expect(tooBig.statusCode, 413);
      final badIndex = await guard((c) => chunk.onRequest(c, uploadId, 'x'))(
        ctx('PUT', '/uploads/$uploadId/chunks/x', raw: [1]),
      );
      expect(badIndex.statusCode, 400);
    },
  );
}
