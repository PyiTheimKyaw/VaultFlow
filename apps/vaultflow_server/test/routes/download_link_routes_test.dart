// Route handlers are imported by relative path, as in the other route tests.
// ignore_for_file: simple_directive_paths
import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

import '../../routes/documents/[id]/content.dart' as content;
import '../../routes/documents/[id]/download-url.dart' as link;
import '../../routes/sync/events.dart' as events;
import '../helpers.dart';

void main() {
  late FakeClock clock;
  late ServerContext server;
  late AuthTokens tokens;
  late String docId;
  final bytes = List<int>.generate(40, (i) => 255 - i);

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 9, 9, 12));
    server = testContext(clock: clock);
    tokens = await server.auth.register(
      const CredentialsRequestFixture().value,
    );
    // A document with content.
    docId = VfId.next();
    final sha = UploadService.hashOf(bytes);
    final now = clock.now().toIso8601String();
    await server.syncStore.upsert(
      tokens.userId,
      StoredEntity(
        type: EntityType.document,
        id: docId,
        version: 1,
        snapshot: {
          'id': docId,
          'name': 'räpport.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 40,
          'sha256': sha,
          'version': 1,
          'created_at': now,
          'updated_at': now,
        },
      ),
    );
    final created = await server.uploads.create(
      tokens.userId,
      UploadSessionCreateRequest(
        documentId: docId,
        totalBytes: 40,
        sha256: sha,
        mimeType: 'application/pdf',
        chunkSize: 40,
      ),
    );
    await server.uploads.putChunk(tokens.userId, created.uploadId!, 0, bytes);
    await server.uploads.complete(tokens.userId, 'dev', created.uploadId!);
  });

  RequestContext ctx(
    String method,
    String path, {
    bool bearer = true,
    Map<String, String> headers = const {},
  }) {
    final context = MockRequestContext();
    final request = Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        if (bearer) 'authorization': 'Bearer ${tokens.accessToken}',
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

  Handler guard(Handler h) => errorHandler()(authOrDownloadToken()(h));

  test('a signed link downloads as an attachment without a bearer', () async {
    final issued = await guard((c) => link.onRequest(c, docId))(
      ctx('POST', '/documents/$docId/download-url'),
    );
    expect(issued.statusCode, 200);
    final body = await decodeJson(issued);
    final url = body['url']! as String;
    expect(url, startsWith('/documents/$docId/content?token='));
    expect(
      DateTime.parse(body['expires_at']! as String),
      clock.now().add(const Duration(minutes: 5)),
    );

    final fetched = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', url, bearer: false),
    );
    expect(fetched.statusCode, 200);
    expect(fetched.headers['Content-Type'], 'application/pdf');
    expect(
      fetched.headers['Content-Disposition'],
      'attachment; filename="r_pport.pdf"; '
      "filename*=UTF-8''r%C3%A4pport.pdf",
    );
    expect(
      await fetched.bytes().toList().then((c) => c.expand((x) => x)),
      bytes,
    );

    // Bearer requests are unchanged: inline, no disposition.
    final inline = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', '/documents/$docId/content'),
    );
    expect(inline.headers.containsKey('Content-Disposition'), isFalse);
  });

  test('links are bound to one document and expire', () async {
    final issued = await guard((c) => link.onRequest(c, docId))(
      ctx('POST', '/documents/$docId/download-url'),
    );
    final token = Uri.parse((await decodeJson(issued))['url']! as String)
        .queryParameters['token']!;

    final other = await guard((c) => content.onRequest(c, 'other-doc'))(
      ctx('GET', '/documents/other-doc/content?token=$token', bearer: false),
    );
    expect(other.statusCode, 401);

    clock.advance(const Duration(minutes: 6));
    final late = await guard((c) => content.onRequest(c, docId))(
      ctx('GET', '/documents/$docId/content?token=$token', bearer: false),
    );
    expect(late.statusCode, 401);
    expect((await decodeJson(late))['error'], isA<Map<String, Object?>>());

    // No link for a document without content.
    final missing = await guard((c) => link.onRequest(c, 'nope'))(
      ctx('POST', '/documents/nope/download-url'),
    );
    expect(missing.statusCode, 404);
  });

  test('sync events stream announces changes from other devices', () async {
    final response = await guard(events.onRequest)(
      ctx('GET', '/sync/events?poll_ms=10&exclude_device=me'),
    );
    expect(response.statusCode, 200);
    expect(response.headers['Content-Type'], 'text/event-stream');

    final received = <String>[];
    final done = Completer<void>();
    final sub = response
        .bytes()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          received.add(line);
          if (line.startsWith('data:') && !done.isCompleted) done.complete();
        });

    // Own-device changes are ignored; another device's change is pushed.
    await server.syncStore.appendChange(
      userId: tokens.userId,
      deviceId: 'me',
      entityType: EntityType.note,
      entityId: 'n1',
      op: SyncOp.create,
      version: 1,
      payload: const {},
      createdAt: DateTime.utc(2026, 9, 9),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(received.where((l) => l.startsWith('event:')), isEmpty);
    await server.syncStore.appendChange(
      userId: tokens.userId,
      deviceId: 'other',
      entityType: EntityType.note,
      entityId: 'n2',
      op: SyncOp.create,
      version: 1,
      payload: const {},
      createdAt: DateTime.utc(2026, 9, 9),
    );
    await done.future.timeout(const Duration(seconds: 2));
    await sub.cancel();
    expect(received.first, 'retry: 3000');
    expect(received, contains('event: change'));
    final data = received.firstWhere((l) => l.startsWith('data:'));
    // Sequence 1 was the upload completing in setUp, 2 our own change.
    final latest = (await server.syncStore.latestChange(tokens.userId))!;
    expect(latest.seq, 3);
    expect(jsonDecode(data.substring(5)), {'seq': 3});
  });

  test('InMemorySyncStore.latestChange', () async {
    final store = InMemorySyncStore();
    expect(await store.latestChange('u'), isNull);
    await store.appendChange(
      userId: 'u',
      deviceId: 'd',
      entityType: EntityType.note,
      entityId: 'n',
      op: SyncOp.create,
      version: 1,
      payload: const {},
      createdAt: DateTime.utc(2026, 9, 9),
    );
    await store.appendChange(
      userId: 'v',
      deviceId: 'd',
      entityType: EntityType.note,
      entityId: 'n',
      op: SyncOp.create,
      version: 1,
      payload: const {},
      createdAt: DateTime.utc(2026, 9, 9),
    );
    expect((await store.latestChange('u'))!.entityId, 'n');
    expect((await store.latestChange('u'))!.userId, 'u');
  });
}
