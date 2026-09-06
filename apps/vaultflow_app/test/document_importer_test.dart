import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/testing.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  late VaultFlowDatabase db;
  late Directory dir;
  late DocumentImporter importer;
  late DriftVaultRepository repo;

  setUp(() async {
    db = openInMemoryDatabase();
    dir = await Directory.systemTemp.createTemp('vf_import_');
    repo = DriftVaultRepository(db);
    importer = DocumentImporter(
      useCases: VaultUseCases(vault: repo),
      cacheDirectory: TempCacheDirectory(dir.path),
      isWeb: false,
    );
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'copies the file into a content-addressed cache and registers it',
    () async {
      const text = 'hello vault';
      final result = await importer.importOne(
        importSourceFromString('hello.txt', text),
      );
      final doc = result.getOrThrow();
      final expectedHash = sha256.convert(text.codeUnits).toString();

      expect(doc.sha256, expectedHash);
      expect(doc.sizeBytes, text.length);
      expect(doc.mimeType, 'text/plain');
      expect(doc.cacheState, CacheState.complete);
      expect(doc.localPath, isNotNull);
      expect(p.isWithin(dir.path, doc.localPath!), isTrue);
      expect(File(doc.localPath!).readAsStringSync(), text);
      expect(Directory(p.join(dir.path, 'incoming')).listSync(), isEmpty);

      final stored = await repo.getDocument(doc.id);
      expect(stored, doc);
    },
  );

  test('identical content shares one cached copy', () async {
    final a = (await importer.importOne(
      importSourceFromString('a.txt', 'same'),
    )).getOrThrow();
    final b = (await importer.importOne(
      importSourceFromString('a.txt', 'same'),
    )).getOrThrow();
    expect(a.localPath, b.localPath);
    expect(a.id, isNot(b.id));
  });

  test('web mode hashes without writing to disk', () async {
    final webImporter = DocumentImporter(
      useCases: VaultUseCases(vault: repo),
      cacheDirectory: TempCacheDirectory(dir.path),
      isWeb: true,
    );
    final doc = (await webImporter.importOne(
      importSourceFromBytes('img.png', [1, 2, 3]),
    )).getOrThrow();
    expect(doc.localPath, isNull);
    expect(doc.cacheState, CacheState.none);
    expect(doc.mimeType, 'image/png');
    expect(dir.listSync(), isEmpty);
  });

  test('stream errors become StorageFailure and leave no document', () async {
    final result = await importer.importOne(
      ImportSource(name: 'bad.bin', bytes: Stream.error(Exception('read'))),
    );
    expect(result.failureOrNull, isA<StorageFailure>());
    expect((await repo.watchContents(null).first).documents, isEmpty);
  });
}
