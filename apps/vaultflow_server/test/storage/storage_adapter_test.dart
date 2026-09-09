import 'dart:io';

import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// The [StorageAdapter] contract, run against the local filesystem always
/// and against S3 when `TEST_S3_ENDPOINT` (host:port) points at a MinIO
/// with the docker-compose defaults:
///
///   docker compose up -d minio minio-init
///   TEST_S3_ENDPOINT=localhost:9000 dart test test/storage
void main() {
  group('LocalFsStorage', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('vf_storage_'));
    tearDown(() => root.delete(recursive: true));
    storageContract(() => LocalFsStorage(root.path));
  });

  group('S3Storage', () {
    final endpoint = Platform.environment['TEST_S3_ENDPOINT'];
    final skip = endpoint == null || endpoint.isEmpty
        ? 'set TEST_S3_ENDPOINT=host:port to run against MinIO'
        : null;
    final env = Platform.environment;
    S3Storage make() {
      final parts = endpoint!.split(':');
      return S3Storage(
        S3Config(
          endpoint: parts.first,
          port: parts.length > 1 ? int.parse(parts[1]) : 9000,
          useSsl: false,
          accessKey: env['S3_ACCESS_KEY'] ?? 'vaultflow',
          secretKey: env['S3_SECRET_KEY'] ?? 'vaultflow-secret',
          bucket: env['S3_BUCKET'] ?? 'vaultflow',
        ),
      );
    }

    storageContract(make, skip: skip);
  });
}

void storageContract(StorageAdapter Function() make, {String? skip}) {
  Future<List<int>> drain(Stream<List<int>> s) async => [
    for (final c in await s.toList()) ...c,
  ];

  test('parts assemble in order, ranges read back, delete removes', () async {
    final storage = make();
    final uploadId = VfId.random();
    final key = 'u/test/${VfId.random()}';
    final a = List<int>.generate(1000, (i) => i % 251);
    final b = List<int>.generate(1000, (i) => (i * 7) % 253);
    final c = List<int>.generate(500, (i) => 255 - i % 256);

    await storage.putPart(uploadId, 1, b);
    await storage.putPart(uploadId, 0, [9, 9, 9]);
    // Re-putting a part replaces it (idempotent retries).
    await storage.putPart(uploadId, 0, a);
    await storage.putPart(uploadId, 2, c);

    expect(await storage.assemble(uploadId, 3, key), 2500);
    expect(await storage.sizeOf(key), 2500);
    expect(await drain(storage.read(key)), [...a, ...b, ...c]);
    expect(await drain(storage.read(key, start: 995, end: 1004)), [
      ...a.sublist(995),
      ...b.sublist(0, 5),
    ]);
    expect(await drain(storage.read(key, start: 2490)), c.sublist(490));

    await storage.delete(key);
    expect(await storage.sizeOf(key), isNull);
    expect(await storage.sizeOf('u/test/never-written'), isNull);
  }, skip: skip);

  test('abort discards parts', () async {
    final storage = make();
    final uploadId = VfId.random();
    await storage.putPart(uploadId, 0, [1, 2, 3]);
    await storage.abort(uploadId);
    await expectLater(
      () => storage.assemble(uploadId, 1, 'u/test/${VfId.random()}'),
      throwsA(anything),
    );
  }, skip: skip);

  test('upload service round trip: chunks, verify, dedupe, content', () async {
    final storage = make();
    final uploadStore = InMemoryUploadStore();
    final sync = InMemorySyncStore();
    final uploads = UploadService(
      store: uploadStore,
      storage: storage,
      sync: sync,
      maxChunkSize: 1024,
    );
    final content = ContentService(
      sync: sync,
      uploads: uploadStore,
      storage: storage,
    );
    const user = 'user-s3';
    final bytes = List<int>.generate(2500, (i) => (i * 31) % 256);
    final hash = UploadService.hashOf(bytes);

    final created = await uploads.create(
      user,
      UploadSessionCreateRequest(
        documentId: VfId.next(),
        totalBytes: 2500,
        sha256: hash,
        mimeType: 'application/octet-stream',
        chunkSize: 1024,
      ),
    );
    final id = created.uploadId!;
    await uploads.putChunk(user, id, 2, bytes.sublist(2048));
    await uploads.putChunk(user, id, 0, bytes.sublist(0, 1024));
    await uploads.putChunk(user, id, 1, bytes.sublist(1024, 2048));
    final done = await uploads.complete(user, 'dev', id);
    expect(done.storageKey, UploadService.storageKeyFor(user, hash));
    expect(await storage.sizeOf(done.storageKey), 2500);

    // Same content again: instant dedupe, no second object.
    final again = await uploads.create(
      user,
      UploadSessionCreateRequest(
        documentId: VfId.next(),
        totalBytes: 2500,
        sha256: hash,
        mimeType: 'application/octet-stream',
        chunkSize: 1024,
      ),
    );
    expect(again.dedup, isTrue);
    expect(again.storageKey, done.storageKey);

    // A corrupted upload is rejected and leaves nothing behind.
    final badHash = UploadService.hashOf([0]);
    final bad = await uploads.create(
      user,
      UploadSessionCreateRequest(
        documentId: VfId.next(),
        totalBytes: 3,
        sha256: badHash,
        mimeType: 'application/octet-stream',
        chunkSize: 1024,
      ),
    );
    await uploads.putChunk(user, bad.uploadId!, 0, [1, 2, 3]);
    await expectLater(
      () => uploads.complete(user, 'dev', bad.uploadId!),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.hashMismatch,
        ),
      ),
    );
    expect(
      await storage.sizeOf(UploadService.storageKeyFor(user, badHash)),
      isNull,
    );

    // Ranged read through the content service.
    final docId = VfId.next();
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
          'mime_type': 'application/octet-stream',
          'size_bytes': 2500,
          'sha256': hash,
          'storage_key': done.storageKey,
          'version': 1,
          'created_at': now,
          'updated_at': now,
        },
      ),
    );
    final tail = await content.read(user, docId, rangeHeader: 'bytes=2000-');
    expect((tail.start, tail.end, tail.total), (2000, 2499, 2500));
    expect(await drain(tail.stream), bytes.sublist(2000));
    await storage.delete(done.storageKey);
  }, skip: skip);
}
