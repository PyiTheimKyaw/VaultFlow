// Drives the real engine over HTTP against a running API. Skipped unless
// VAULTFLOW_LIVE_API points at a server (see docs/MANUAL_TESTING.md):
//
//   scripts/dev_server.sh
//   VAULTFLOW_LIVE_API=http://localhost:8080 flutter test test/live
@Tags(['live'])
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_sync/vf_sync.dart';
import 'package:vf_transfer/src/download_worker.dart';
import 'package:vf_transfer/vf_transfer.dart';

final String? _baseUrl = Platform.environment['VAULTFLOW_LIVE_API'];

class _LiveDevice {
  _LiveDevice._(this.name, this.db, this.api, this.engine, this.sync, this.dir);

  static Future<_LiveDevice> signIn(
    String name, {
    required String email,
    required String password,
    required bool register,
  }) async {
    final tokens = InMemoryTokenStore();
    final api = ApiClient(
      DioFactory.create(
        baseUrl: _baseUrl!,
        tokens: tokens,
        onAuthLost: () => fail('$name lost auth'),
      ),
    );
    final request = CredentialsRequest(
      email: email,
      password: password,
      deviceName: name,
      platform: 'macos',
    );
    final auth =
        (register ? await api.register(request) : await api.login(request))
            .getOrThrow();
    await tokens.write(auth);
    final db = openInMemoryDatabase();
    final dir = Directory.systemTemp.createTempSync('vf_live_$name');
    final engine = TransferEngine(
      db: db,
      api: api,
      cacheRoot: () async => dir.path,
      chunkSize: 1 << 20,
      retryDelay: const Duration(milliseconds: 200),
    );
    final sync = SyncEngine(
      db: db,
      api: api,
      deviceId: auth.deviceId,
      deviceLabel: name,
    );
    await engine.recover();
    return _LiveDevice._(name, db, api, engine, sync, dir);
  }

  final String name;
  final VaultFlowDatabase db;
  final ApiClient api;
  final TransferEngine engine;
  final SyncEngine sync;
  final Directory dir;

  Future<void> close() async {
    engine.dispose();
    sync.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  }
}

void main() {
  if (_baseUrl == null) {
    test('live smoke', () {}, skip: 'set VAULTFLOW_LIVE_API to run');
    return;
  }
  late _LiveDevice a;
  late _LiveDevice b;

  setUpAll(() async {
    final email = 'live-${VfId.random()}@example.com';
    const password = 'correct horse battery staple';
    a = await _LiveDevice.signIn(
      'a',
      email: email,
      password: password,
      register: true,
    );
    b = await _LiveDevice.signIn(
      'b',
      email: email,
      password: password,
      register: false,
    );
  });

  tearDownAll(() async {
    await a.close();
    await b.close();
  });

  test(
    'device A uploads 12 MiB in chunks, device B downloads it with Range',
    () async {
      // 1. A imports a 12 MiB file: document + blocked create + upload.
      const size = 12 * 1024 * 1024 + 4321;
      final file = File(p.join(a.dir.path, 'src', 'big.bin'));
      file.parent.createSync(recursive: true);
      final r = Random(42);
      final sink = file.openWrite();
      for (var left = size; left > 0; left -= min(left, 1 << 16)) {
        sink.add(List<int>.generate(min(left, 1 << 16), (_) => r.nextInt(256)));
      }
      await sink.close();
      final hash = await Hasher.ofFile(file.path);
      final sessionId = VfId.next();
      final now = DateTime.now().toUtc();
      final doc = Document(
        id: VfId.next(),
        name: 'big.bin',
        mimeType: 'application/octet-stream',
        sizeBytes: size,
        sha256: hash,
        localPath: file.path,
        cacheState: CacheState.complete,
        createdAt: now,
        updatedAt: now,
      );
      final vaultA = DriftVaultRepository(a.db);
      await vaultA.createDocument(doc, dependsOnTransfer: sessionId);
      await a.engine.enqueueUpload(
        documentId: doc.id,
        localPath: file.path,
        totalBytes: size,
        sha256: hash,
        sessionId: sessionId,
      );
      await a.engine.drain(timeout: const Duration(minutes: 2));
      final upload = (await a.db.transfersDao.getSession(sessionId))!;
      expect(upload.state, 'completed', reason: upload.lastError);
      expect((await a.db.transfersDao.getChunks(sessionId)).length, 13);

      // 2. The create was released with the storage key and pushes.
      final create = (await a.db.outboxDao.getAll()).single;
      expect(create.state, OutboxState.pending);
      expect(create.dependsOnTransfer, isNull);
      final pushed = await a.sync.syncNow();
      expect(pushed.isOk, isTrue, reason: '${pushed.failure}');
      expect(await a.db.outboxDao.getAll(), isEmpty);
      final storedA = (await vaultA.getDocument(doc.id))!;
      expect(storedA.storageKey, isNotNull);
      expect(storedA.syncStatus, SyncStatus.synced);

      // 3. B pulls the document (no bytes yet) and downloads it.
      final pulled = await b.sync.syncNow();
      expect(pulled.isOk, isTrue, reason: '${pulled.failure}');
      final vaultB = DriftVaultRepository(b.db);
      final remote = (await vaultB.getDocument(doc.id))!;
      expect(remote.cacheState, CacheState.none);
      expect(remote.storageKey, storedA.storageKey);
      final downloadId = await b.engine.enqueueDownload(remote);
      await b.engine.drain(timeout: const Duration(minutes: 2));
      final download = (await b.db.transfersDao.getSession(downloadId))!;
      expect(download.state, 'completed', reason: download.lastError);
      final cached = (await vaultB.getDocument(doc.id))!;
      expect(cached.cacheState, CacheState.complete);
      expect(await Hasher.ofFile(cached.localPath!), hash);
      expect(File(cached.localPath!).lengthSync(), size);

      // 4. Importing the same bytes again is an instant dedupe.
      final again = VfId.next();
      final twin = doc.copyWith(id: VfId.next(), name: 'twin.bin');
      await vaultA.createDocument(twin, dependsOnTransfer: again);
      await a.engine.enqueueUpload(
        documentId: twin.id,
        localPath: file.path,
        totalBytes: size,
        sha256: hash,
        sessionId: again,
      );
      await a.engine.drain();
      expect((await a.db.transfersDao.getSession(again))!.state, 'completed');
      expect(
        int.parse((await a.db.settingsDao.getSyncState('dedupe_saved_bytes'))!),
        size,
      );

      // Push the twin so the server knows the document.
      expect((await a.sync.syncNow()).isOk, isTrue);

      // 5. A download resumes from an existing .part: seed the first 5 MiB
      // and the worker must fetch the rest with a Range request.
      final partial = remote.copyWith(id: twin.id, name: 'twin.bin');
      await DriftSyncRepository(b.db).applyRemoteSnapshot(
        EntityType.document,
        DocumentDto(
          id: twin.id,
          name: 'twin.bin',
          mimeType: twin.mimeType,
          sizeBytes: size,
          sha256: hash,
          version: 1,
          createdAt: now,
          updatedAt: now,
          storageKey: storedA.storageKey,
        ).toJson(),
        version: 1,
      );
      const seeded = 5 * 1024 * 1024;
      final target = DownloadWorker.cachePathFor(b.dir.path, partial);
      final part = File('$target.part')..parent.createSync(recursive: true);
      final raf = file.openSync();
      part.writeAsBytesSync(raf.readSync(seeded));
      raf.closeSync();
      final resumedId = await b.engine.enqueueDownload(partial);
      await b.engine.drain(timeout: const Duration(minutes: 2));
      final resumed = (await b.db.transfersDao.getSession(resumedId))!;
      expect(resumed.state, 'completed', reason: resumed.lastError);
      expect(part.existsSync(), isFalse);
      expect(
        await Hasher.ofFile((await vaultB.getDocument(twin.id))!.localPath!),
        hash,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
