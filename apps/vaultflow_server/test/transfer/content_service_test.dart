import 'dart:io';

import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  late Directory root;
  late InMemoryUploadStore store;
  late InMemorySyncStore sync;
  late ContentService content;
  late String docId;
  const user = 'user-1';
  final bytes = List<int>.generate(100, (i) => i);

  setUp(() async {
    root = Directory.systemTemp.createTempSync('vf_content_');
    store = InMemoryUploadStore();
    sync = InMemorySyncStore();
    final storage = LocalFsStorage(root.path);
    final uploads = UploadService(
      store: store,
      storage: storage,
      sync: sync,
      maxChunkSize: 100,
    );
    content = ContentService(sync: sync, uploads: store, storage: storage);
    docId = VfId.next();
    final now = DateTime.utc(2026).toIso8601String();
    await sync.upsert(
      user,
      StoredEntity(
        type: EntityType.document,
        id: docId,
        version: 1,
        snapshot: {
          'id': docId,
          'name': 'n',
          'mime_type': 'text/plain',
          'size_bytes': 100,
          'sha256': UploadService.hashOf(bytes),
          'version': 1,
          'created_at': now,
          'updated_at': now,
        },
      ),
    );
    final created = await uploads.create(
      user,
      UploadSessionCreateRequest(
        documentId: docId,
        totalBytes: 100,
        sha256: UploadService.hashOf(bytes),
        mimeType: 'text/plain',
        chunkSize: 100,
      ),
    );
    await uploads.putChunk(user, created.uploadId!, 0, bytes);
    await uploads.complete(user, 'dev', created.uploadId!);
  });

  tearDown(() => root.delete(recursive: true));

  Future<List<int>> drain(Stream<List<int>> s) async => [
    for (final c in await s.toList()) ...c,
  ];

  test('whole object and ranges', () async {
    final whole = await content.read(user, docId);
    expect(whole.isPartial, isFalse);
    expect(whole.etag, UploadService.hashOf(bytes));
    expect(whole.mimeType, 'text/plain');
    expect(await drain(whole.stream), bytes);

    final tail = await content.read(user, docId, rangeHeader: 'bytes=90-');
    expect(
      (tail.start, tail.end, tail.total, tail.isPartial),
      (90, 99, 100, true),
    );
    expect(await drain(tail.stream), bytes.sublist(90));

    final mid = await content.read(user, docId, rangeHeader: 'bytes=10-19');
    expect(await drain(mid.stream), bytes.sublist(10, 20));

    final suffix = await content.read(user, docId, rangeHeader: 'bytes=-5');
    expect(await drain(suffix.stream), bytes.sublist(95));

    final clamped = await content.read(
      user,
      docId,
      rangeHeader: 'bytes=50-500',
    );
    expect(clamped.end, 99);
  });

  test(
    'unsatisfiable ranges, unknown documents and documents without content',
    () async {
      await expectLater(
        content.read(user, docId, rangeHeader: 'bytes=100-'),
        throwsA(isA<RangeNotSatisfiable>()),
      );
      await expectLater(
        content.read(user, docId, rangeHeader: 'bytes=abc'),
        throwsA(isA<RangeNotSatisfiable>()),
      );
      await expectLater(
        content.read(user, VfId.next()),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        content.read('user-2', docId),
        throwsA(isA<ApiException>()),
      );
      final bare = VfId.next();
      await sync.upsert(
        user,
        StoredEntity(
          type: EntityType.document,
          id: bare,
          version: 1,
          snapshot: {'id': bare},
        ),
      );
      await expectLater(
        content.read(user, bare),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.notFound,
          ),
        ),
      );
    },
  );
}
