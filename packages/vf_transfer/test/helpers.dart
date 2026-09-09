import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:vaultflow_server/vaultflow_server.dart' as server;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/testing.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_transfer/vf_transfer.dart';

/// Counts and optionally stalls part writes, so tests can prove a part is
/// never uploaded twice and can freeze an upload mid-way.
class CountingStorage implements server.StorageAdapter {
  CountingStorage(this.inner);

  final server.StorageAdapter inner;
  final Map<int, int> partWrites = {};

  /// Awaited before each part write; tests complete it to let uploads
  /// through.
  Future<void> Function(int index)? beforePart;

  @override
  Future<void> putPart(String uploadId, int index, List<int> bytes) async {
    await beforePart?.call(index);
    partWrites.update(index, (n) => n + 1, ifAbsent: () => 1);
    await inner.putPart(uploadId, index, bytes);
  }

  @override
  Future<int> assemble(String uploadId, int count, String key) =>
      inner.assemble(uploadId, count, key);

  @override
  Future<void> abort(String uploadId) => inner.abort(uploadId);

  @override
  Future<int?> sizeOf(String key) => inner.sizeOf(key);

  @override
  Stream<List<int>> read(String key, {int? start, int? end}) =>
      inner.read(key, start: start, end: end);

  @override
  Future<void> delete(String key) => inner.delete(key);
}

/// The real server upload/content services behind a fake HTTP adapter.
class FakeTransferServer {
  FakeTransferServer({FakeClock? clock, int maxChunkSize = 1 << 20})
    : clock = clock ?? FakeClock(DateTime.utc(2026, 9, 9, 9)) {
    root = Directory.systemTemp.createTempSync('vf_server_storage_');
    storage = CountingStorage(server.LocalFsStorage(root.path));
    uploads = server.UploadService(
      store: uploadStore,
      storage: storage,
      sync: syncStore,
      clock: this.clock,
      maxChunkSize: maxChunkSize,
    );
    content = server.ContentService(
      sync: syncStore,
      uploads: uploadStore,
      storage: storage,
    );
    adapter
      ..on('POST', ApiPaths.uploads, _create)
      ..on('GET', '${ApiPaths.uploads}/*', _status)
      ..on('PUT', '${ApiPaths.uploads}/*', _chunk)
      ..on('POST', '${ApiPaths.uploads}/*', _complete)
      ..on('GET', '/documents/*', _content);
  }

  final adapter = FakeAdapter();
  final syncStore = server.InMemorySyncStore();
  final uploadStore = server.InMemoryUploadStore();
  late final Directory root;
  late final CountingStorage storage;
  late final server.UploadService uploads;
  late final server.ContentService content;
  final FakeClock clock;
  final Map<String, (String, String)> sessions = {};

  /// Number of upcoming chunk PUTs that fail with a connection error.
  int failNextChunkPuts = 0;

  /// Downloads: drop the connection after this many bytes, this many times.
  int dropDownloadAfterBytes = -1;
  int dropDownloadsRemaining = 0;

  /// Awaited before each download stream starts (pause tests).
  Future<void> Function()? beforeDownload;

  int chunkPuts = 0;
  int downloads = 0;

  (String, String) _who(RequestOptions o) {
    final token = (o.headers['Authorization'] as String? ?? '').replaceFirst(
      'Bearer ',
      '',
    );
    return sessions[token] ?? (throw StateError('unknown token'));
  }

  FakeResponse _error(server.ApiException e) =>
      FakeResponse(e.code.httpStatus, e.error.toEnvelope());

  Future<FakeResponse> _create(RequestOptions o) async {
    final (userId, _) = _who(o);
    try {
      final r = await uploads.create(
        userId,
        UploadSessionCreateRequest.fromJson(
          jsonDecode(jsonEncode(o.data)) as Map<String, Object?>,
        ),
      );
      return FakeResponse(r.dedup ? 200 : 201, r.toJson());
    } on server.ApiException catch (e) {
      return _error(e);
    }
  }

  String _idOf(RequestOptions o) => o.path.split('/')[2];

  Future<FakeResponse> _status(RequestOptions o) async {
    final (userId, _) = _who(o);
    try {
      return FakeResponse(
        200,
        (await uploads.status(userId, _idOf(o))).toJson(),
      );
    } on server.ApiException catch (e) {
      return _error(e);
    }
  }

  Future<FakeResponse> _chunk(RequestOptions o) async {
    chunkPuts++;
    if (failNextChunkPuts > 0) {
      failNextChunkPuts--;
      throw DioException.connectionError(requestOptions: o, reason: 'dropped');
    }
    final (userId, _) = _who(o);
    final index = int.parse(o.path.split('/').last);
    final body = o.extra[FakeAdapter.bodyExtra] as Uint8List;
    try {
      final r = await uploads.putChunk(
        userId,
        _idOf(o),
        index,
        body,
        declaredSha256: o.headers[ApiPaths.chunkHashHeader] as String?,
      );
      return FakeResponse(200, r.toJson());
    } on server.ApiException catch (e) {
      return _error(e);
    }
  }

  Future<FakeResponse> _complete(RequestOptions o) async {
    final (userId, deviceId) = _who(o);
    try {
      return FakeResponse(
        200,
        (await uploads.complete(userId, deviceId, _idOf(o))).toJson(),
      );
    } on server.ApiException catch (e) {
      return _error(e);
    }
  }

  Future<FakeResponse> _content(RequestOptions o) async {
    downloads++;
    final (userId, _) = _who(o);
    final docId = o.path.split('/')[2];
    await beforeDownload?.call();
    final server.ContentRange range;
    try {
      range = await content.read(
        userId,
        docId,
        rangeHeader: o.headers['Range'] as String?,
      );
    } on server.RangeNotSatisfiable {
      return const FakeResponse(416);
    } on server.ApiException catch (e) {
      return _error(e);
    }
    final drop = dropDownloadsRemaining > 0 ? dropDownloadAfterBytes : -1;
    if (drop >= 0) dropDownloadsRemaining--;
    Stream<Uint8List> body() async* {
      var sent = 0;
      await for (final chunk in range.stream) {
        if (drop >= 0 && sent + chunk.length > drop) {
          final keep = drop - sent;
          if (keep > 0) yield Uint8List.fromList(chunk.sublist(0, keep));
          throw const SocketException('connection reset');
        }
        sent += chunk.length;
        yield Uint8List.fromList(chunk);
      }
    }

    return FakeResponse.stream(
      range.isPartial ? 206 : 200,
      body(),
      headers: {
        'etag': '"${range.etag}"',
        'content-length': '${range.length}',
        'accept-ranges': 'bytes',
        if (range.isPartial)
          'content-range': 'bytes ${range.start}-${range.end}/${range.total}',
      },
    );
  }

  /// Registers a document on the server as if it had synced (needed for
  /// downloads).
  Future<void> registerDocument(
    String userId,
    Document doc,
    String storageKey,
  ) => syncStore.upsert(
    userId,
    server.StoredEntity(
      type: EntityType.document,
      id: doc.id,
      version: 1,
      snapshot: {
        ...DocumentDto(
          id: doc.id,
          name: doc.name,
          mimeType: doc.mimeType,
          sizeBytes: doc.sizeBytes,
          sha256: doc.sha256,
          version: 1,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          storageKey: storageKey,
        ).toJson(),
      },
    ),
  );

  Future<void> dispose() => root.delete(recursive: true);
}

/// One device with its own database, cache directory and engine.
class Device {
  Device._(
    this.name,
    this.db,
    this.engine,
    this.cacheDir,
    this.userId,
    this.deviceId,
    this.server,
  );

  static Future<Device> create(
    FakeTransferServer server, {
    required String name,
    String userId = 'user-1',
    VaultFlowDatabase? db,
    Directory? cacheDir,
    int chunkSize = 64 * 1024,
    int maxAttempts = 8,
    Duration retryDelay = const Duration(milliseconds: 20),
  }) async {
    final database = db ?? openInMemoryDatabase();
    final dir =
        cacheDir ?? Directory.systemTemp.createTempSync('vf_cache_$name');
    final deviceId = VfId.next();
    final token = 'token-$name-${VfId.random()}';
    server.sessions[token] = (userId, deviceId);
    final dio = DioFactory.create(
      baseUrl: 'https://api.test',
      tokens: InMemoryTokenStore(
        AuthTokens(
          accessToken: token,
          refreshToken: 'r',
          deviceId: deviceId,
          userId: userId,
          expiresIn: 900,
        ),
      ),
      onAuthLost: () {},
    )..httpClientAdapter = server.adapter;
    final engine = TransferEngine(
      db: database,
      api: ApiClient(dio),
      cacheRoot: () async => dir.path,
      chunkSize: chunkSize,
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
    await engine.recover();
    return Device._(name, database, engine, dir, userId, deviceId, server);
  }

  final String name;
  final VaultFlowDatabase db;
  final TransferEngine engine;
  final Directory cacheDir;
  final String userId;
  final String deviceId;
  final FakeTransferServer server;

  late final vault = DriftVaultRepository(db);

  /// Writes a deterministic pseudo-random file of [size] bytes.
  Future<File> makeFile(String name, int size, {int seed = 1}) async {
    final file = File(p.join(cacheDir.path, 'src', name));
    await file.parent.create(recursive: true);
    final r = Random(seed);
    final sink = file.openWrite();
    var left = size;
    while (left > 0) {
      final n = min(left, 64 * 1024);
      sink.add(List<int>.generate(n, (_) => r.nextInt(256)));
      left -= n;
    }
    await sink.close();
    return file;
  }

  /// Imports [file] the way the app does: document row + blocked create,
  /// then an upload session.
  Future<(Document, String)> importFile(File file) async {
    final bytes = await file.length();
    final hash = await Hasher.ofFile(file.path);
    final sessionId = VfId.next();
    final doc = Document(
      id: VfId.next(),
      name: p.basename(file.path),
      mimeType: 'application/octet-stream',
      sizeBytes: bytes,
      sha256: hash,
      localPath: file.path,
      cacheState: CacheState.complete,
      createdAt: DateTime.utc(2026, 9, 9),
      updatedAt: DateTime.utc(2026, 9, 9),
    );
    await vault.createDocument(doc, dependsOnTransfer: sessionId);
    await engine.enqueueUpload(
      documentId: doc.id,
      localPath: file.path,
      totalBytes: bytes,
      sha256: hash,
      sessionId: sessionId,
    );
    return (doc, sessionId);
  }

  Future<TransferSessionRow> session(String id) async =>
      (await db.transfersDao.getSession(id))!;

  Future<List<OutboxRow>> outbox() => db.outboxDao.getAll();

  Future<void> close({bool keepDb = false}) async {
    engine.dispose();
    if (!keepDb) await db.close();
  }
}

abstract final class VfIdFixture {
  static String next() => VfId.next();
}

/// Inserts a document as if it had been pulled from the server (synced, no
/// local bytes).
abstract final class DriftSyncRepositoryFixture {
  static Future<void> insertRemote(
    Device device,
    Document doc,
    String storageKey,
  ) => DriftSyncRepository(device.db).applyRemoteSnapshot(
    EntityType.document,
    DocumentDto(
      id: doc.id,
      name: doc.name,
      mimeType: doc.mimeType,
      sizeBytes: doc.sizeBytes,
      sha256: doc.sha256,
      version: 1,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      storageKey: storageKey,
    ).toJson(),
    version: 1,
  );
}
