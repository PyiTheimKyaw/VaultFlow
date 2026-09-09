import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  late Directory root;
  late InMemoryUploadStore store;
  late InMemorySyncStore sync;
  late FakeClock clock;
  late UploadService service;
  const user = 'user-1';
  const device = 'device-a';

  setUp(() {
    root = Directory.systemTemp.createTempSync('vf_uploads_');
    store = InMemoryUploadStore();
    sync = InMemorySyncStore();
    clock = FakeClock(DateTime.utc(2026, 9, 9, 8));
    service = UploadService(
      store: store,
      storage: LocalFsStorage(root.path),
      sync: sync,
      clock: clock,
      maxChunkSize: 64,
    );
  });

  tearDown(() => root.delete(recursive: true));

  List<int> content(int size, [int seed = 1]) {
    final r = Random(seed);
    return List<int>.generate(size, (_) => r.nextInt(256));
  }

  UploadSessionCreateRequest request(
    List<int> bytes, {
    int chunk = 16,
    String? docId,
  }) => UploadSessionCreateRequest(
    documentId: docId ?? VfId.next(),
    totalBytes: bytes.length,
    sha256: UploadService.hashOf(bytes),
    mimeType: 'application/octet-stream',
    chunkSize: chunk,
  );

  List<List<int>> split(List<int> bytes, int chunk) => [
    for (var i = 0; i < bytes.length; i += chunk)
      bytes.sublist(i, min(i + chunk, bytes.length)),
  ];

  Future<UploadCompleteResponse> uploadAll(
    List<int> bytes, {
    int chunk = 16,
    String? docId,
  }) async {
    final created = await service.create(
      user,
      request(bytes, chunk: chunk, docId: docId),
    );
    final id = created.uploadId!;
    final parts = split(bytes, chunk);
    for (var i = 0; i < parts.length; i++) {
      await service.putChunk(
        user,
        id,
        i,
        parts[i],
        declaredSha256: UploadService.hashOf(parts[i]),
      );
    }
    return await service.complete(user, device, id);
  }

  test(
    'chunks arrive in any order, idempotently, and assemble to the exact bytes',
    () async {
      final bytes = content(50);
      final created = await service.create(user, request(bytes));
      expect(created.dedup, isFalse);
      expect(created.chunkSize, 16);
      final id = created.uploadId!;
      final parts = split(bytes, 16);
      expect(parts, hasLength(4));

      await service.putChunk(user, id, 3, parts[3]);
      await service.putChunk(user, id, 1, parts[1]);
      await service.putChunk(
        user,
        id,
        1,
        parts[1],
        declaredSha256: UploadService.hashOf(parts[1]),
      );
      final status = await service.status(user, id);
      expect(status.receivedChunks, [1, 3]);

      await expectLater(
        service.complete(user, device, id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.chunkMismatch,
          ),
        ),
      );
      await service.putChunk(user, id, 0, parts[0]);
      await service.putChunk(user, id, 2, parts[2]);
      final done = await service.complete(user, device, id);
      expect(
        done.storageKey,
        UploadService.storageKeyFor(user, UploadService.hashOf(bytes)),
      );
      expect(done.version, 0, reason: 'document not on the server yet');

      final stored = File(
        '${root.path}/u/$user/${done.storageKey.split('/').skip(2).join('/')}',
      );
      expect(stored.readAsBytesSync(), bytes);
      expect(
        Directory('${root.path}/.uploads').listSync(),
        isEmpty,
        reason: 'parts cleaned up',
      );
      expect(
        (await store.findBlob(user, UploadService.hashOf(bytes)))!.sizeBytes,
        50,
      );
      expect(store.sessions[id]!.state, UploadSessionState.completed);
    },
  );

  test(
    'rejects wrong chunk length, wrong declared hash and bad indexes',
    () async {
      final bytes = content(40);
      final id = (await service.create(user, request(bytes))).uploadId!;
      await expectLater(
        service.putChunk(user, id, 0, bytes.sublist(0, 10)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.chunkMismatch,
          ),
        ),
      );
      await expectLater(
        service.putChunk(
          user,
          id,
          0,
          bytes.sublist(0, 16),
          declaredSha256: 'deadbeef',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.chunkMismatch,
          ),
        ),
      );
      await expectLater(
        service.putChunk(user, id, 9, bytes.sublist(0, 16)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.validationFailed,
          ),
        ),
      );
      expect((await service.status(user, id)).receivedChunks, isEmpty);
    },
  );

  test(
    'a lying sha256 is caught at complete and the object is discarded',
    () async {
      final bytes = content(20);
      final lie = UploadService.hashOf(utf8.encode('something else'));
      final created = await service.create(
        user,
        UploadSessionCreateRequest(
          documentId: VfId.next(),
          totalBytes: bytes.length,
          sha256: lie,
          mimeType: 'text/plain',
          chunkSize: 16,
        ),
      );
      final id = created.uploadId!;
      await service.putChunk(user, id, 0, bytes.sublist(0, 16));
      await service.putChunk(user, id, 1, bytes.sublist(16));
      await expectLater(
        service.complete(user, device, id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.hashMismatch,
          ),
        ),
      );
      expect(await store.findBlob(user, lie), isNull);
      expect(
        await LocalFsStorage(root.path)
            .sizeOf(UploadService.storageKeyFor(user, lie)),
        isNull,
      );
      expect(store.sessions[id]!.state, UploadSessionState.aborted);
    },
  );

  test(
    'identical content dedupes: second create returns the key instantly',
    () async {
      final bytes = content(30, 7);
      final first = await uploadAll(bytes);
      final second = await service.create(user, request(bytes));
      expect(second.dedup, isTrue);
      expect(second.storageKey, first.storageKey);
      expect(second.uploadId, isNull);
      // Another user with the same bytes gets their own copy.
      final other = await service.create('user-2', request(bytes));
      expect(other.dedup, isFalse);
    },
  );

  test(
    'complete stamps an existing server document and appends a change',
    () async {
      final docId = VfId.next();
      final now = clock.now().toIso8601String();
      await sync.upsert(
        user,
        StoredEntity(
          type: EntityType.document,
          id: docId,
          version: 1,
          snapshot: {
            'id': docId,
            'name': 'a.bin',
            'mime_type': 'application/octet-stream',
            'size_bytes': 12,
            'sha256': 'x',
            'version': 1,
            'created_at': now,
            'updated_at': now,
          },
        ),
      );
      final done = await uploadAll(content(12), docId: docId);
      expect(done.version, 2);
      final stored = await sync.find(user, EntityType.document, docId);
      expect(stored!.snapshot['storage_key'], done.storageKey);
      expect(sync.changes.single.op, SyncOp.update);
      expect(sync.changes.single.deviceId, device);
      // Completing a second session for the same doc does not bump again.
      expect(await service.ownsBlob(user, done.storageKey), isTrue);
      expect(await service.ownsBlob('user-2', done.storageKey), isFalse);
    },
  );

  test('expired sessions are refused and garbage collected', () async {
    final bytes = content(20);
    final id = (await service.create(user, request(bytes))).uploadId!;
    await service.putChunk(user, id, 0, bytes.sublist(0, 16));
    clock.advance(const Duration(hours: 25));
    await expectLater(
      service.status(user, id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.uploadExpired,
        ),
      ),
    );
    expect(store.sessions.containsKey(id), isFalse);
    expect(
      Directory('${root.path}/.uploads').existsSync() &&
          Directory('${root.path}/.uploads').listSync().isNotEmpty,
      isFalse,
    );
  });

  test(
    'sessions are private to their user; empty files upload as one empty chunk',
    () async {
      final id = (await service.create(user, request(content(20)))).uploadId!;
      await expectLater(
        service.status('user-2', id),
        throwsA(isA<ApiException>()),
      );

      final empty = await service.create(user, request(const []));
      final emptyId = empty.uploadId!;
      expect((await service.status(user, emptyId)).receivedChunks, isEmpty);
      await service.putChunk(user, emptyId, 0, const []);
      final done = await service.complete(user, device, emptyId);
      expect((await store.findBlobByKey(user, done.storageKey))!.sizeBytes, 0);
    },
  );

  test('create validates its inputs', () async {
    Future<void> bad(UploadSessionCreateRequest r) => expectLater(
      service.create(user, r),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.validationFailed,
        ),
      ),
    );
    await bad(request(content(4)).copyWith(documentId: 'nope'));
    await bad(request(content(4)).copyWith(sha256: 'short'));
    await bad(request(content(4)).copyWith(chunkSize: 0));
    await bad(request(content(4)).copyWith(chunkSize: 1 << 20));
    await bad(request(content(4)).copyWith(totalBytes: -1));
  });
}
