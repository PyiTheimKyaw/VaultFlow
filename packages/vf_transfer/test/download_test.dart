import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_transfer/vf_transfer.dart';

import 'helpers.dart';

void main() {
  late FakeTransferServer server;
  late Device a;
  late Device b;
  late Document doc;
  late String contentHash;

  /// A uploads a file; B (same account, no local copy) downloads it.
  setUp(() async {
    server = FakeTransferServer();
    a = await Device.create(server, name: 'A');
    final file = await a.makeFile('shared.bin', 700 * 1024, seed: 3);
    final (uploaded, _) = await a.importFile(file);
    await a.engine.drain();
    final stored = (await a.vault.getDocument(uploaded.id))!;
    contentHash = stored.sha256;
    await server.registerDocument(a.userId, stored, stored.storageKey!);

    b = await Device.create(server, name: 'B', maxAttempts: 4);
    doc = stored.copyWith(localPath: null, cacheState: CacheState.none);
    await DriftSyncRepositoryFixture.insertRemote(b, doc, stored.storageKey!);
  });

  tearDown(() async {
    await a.close();
    await b.close();
    await server.dispose();
  });

  test('downloads, verifies the hash and caches the file', () async {
    final id = await b.engine.enqueueDownload(doc);
    await b.engine.drain();
    final session = await b.session(id);
    expect(session.state, 'completed');
    final cached = (await b.vault.getDocument(doc.id))!;
    expect(cached.cacheState, CacheState.complete);
    expect(cached.localPath, endsWith('shared.bin'));
    expect(await Hasher.ofFile(cached.localPath!), contentHash);
    expect(File('${cached.localPath}.part').existsSync(), isFalse);
    expect(server.downloads, 1);
  });

  test('a dropped connection resumes from the .part offset', () async {
    server
      ..dropDownloadAfterBytes = 300 * 1024
      ..dropDownloadsRemaining = 2;
    final id = await b.engine.enqueueDownload(doc);
    await b.engine.drain();
    expect((await b.session(id)).state, 'completed');
    expect(server.downloads, 3, reason: 'two drops, one full resume');
    final ranges = server.adapter.calls
        .where((c) => c.path.contains('/content'))
        .map((c) => c.headers['Range'])
        .toList();
    expect(ranges.first, isNull);
    expect(ranges.last, startsWith('bytes='));
    expect(
      await Hasher.ofFile((await b.vault.getDocument(doc.id))!.localPath!),
      contentHash,
    );
  });

  test('corrupted content fails verification and leaves no cached file', () async {
    // Flip a byte in the stored object.
    final stored = (await a.vault.getDocument(doc.id))!;
    final objectPath =
        '${server.root.path}/${stored.storageKey!.replaceAll('/', Platform.pathSeparator)}';
    final bytes = File(objectPath).readAsBytesSync();
    bytes[10] = bytes[10] ^ 0xFF;
    File(objectPath).writeAsBytesSync(bytes);

    final id = await b.engine.enqueueDownload(doc);
    await b.engine.drain(timeout: const Duration(seconds: 20));
    final session = await b.session(id);
    expect(session.state, 'failed');
    expect(session.lastError, contains('verification'));
    final local = (await b.vault.getDocument(doc.id))!;
    expect(local.localPath, isNull);
    expect(local.cacheState, CacheState.none);
    expect(File('${session.localPath}.part').existsSync(), isFalse);
  });

  test('pause, resume and cancel', () async {
    final gate = Completer<void>();
    server.beforeDownload = () => gate.future;
    final id = await b.engine.enqueueDownload(doc);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await b.session(id)).state, 'running');
    await b.engine.pause(id);
    expect((await b.session(id)).state, 'paused');
    gate.complete();
    server.beforeDownload = null;
    await Future<void>.delayed(const Duration(milliseconds: 30));

    await b.engine.resume(id);
    await b.engine.drain();
    expect((await b.session(id)).state, 'completed');

    // Cancel a fresh download of another copy.
    final other = doc.copyWith(id: VfIdFixture.next(), name: 'other.bin');
    await DriftSyncRepositoryFixture.insertRemote(
      b,
      other,
      (await a.vault.getDocument(doc.id))!.storageKey!,
    );
    server.beforeDownload = () => Completer<void>().future; // never starts
    final cancelId = await b.engine.enqueueDownload(other);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await b.engine.cancel(cancelId);
    expect((await b.session(cancelId)).state, 'cancelled');
    server.beforeDownload = null;
  });
}
