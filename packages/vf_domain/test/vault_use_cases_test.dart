import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

import 'fakes.dart';

void main() {
  late FakeVaultRepository vault;
  late FakeClock clock;
  late VaultUseCases useCases;
  var counter = 0;

  setUp(() {
    vault = FakeVaultRepository();
    clock = FakeClock(DateTime.utc(2026, 9, 6, 12));
    counter = 0;
    useCases = VaultUseCases(
      vault: vault,
      clock: clock,
      newId: () => 'id-${++counter}',
    );
  });

  group('createFolder', () {
    test('creates a folder at the root with trimmed name', () async {
      final result = await useCases.createFolder(name: '  Docs ');
      final folder = result.getOrThrow();
      expect(folder.id, 'id-1');
      expect(folder.name, 'Docs');
      expect(folder.parentId, isNull);
      expect(folder.createdAt, clock.now());
      expect(folder.syncStatus, SyncStatus.pending);
      expect(vault.folders[folder.id], folder);
    });

    test('rejects empty and illegal names', () async {
      expect(
        (await useCases.createFolder(name: '   ')).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await useCases.createFolder(name: 'a/b')).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await useCases.createFolder(name: 'x' * 256)).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(vault.folders, isEmpty);
    });

    test('rejects an unknown parent', () async {
      final result = await useCases.createFolder(
        name: 'Sub',
        parentId: 'missing',
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('maps repository exceptions to StorageFailure', () async {
      vault.failNextWrite = Exception('disk full');
      final result = await useCases.createFolder(name: 'X');
      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('move', () {
    test('refuses to move a folder into itself or a descendant', () async {
      final a = (await useCases.createFolder(name: 'A')).getOrThrow();
      final b = (await useCases.createFolder(
        name: 'B',
        parentId: a.id,
      )).getOrThrow();
      final c = (await useCases.createFolder(
        name: 'C',
        parentId: b.id,
      )).getOrThrow();

      final intoSelf = await useCases.move(
        type: EntityType.folder,
        id: a.id,
        targetFolderId: a.id,
      );
      expect(intoSelf.failureOrNull, isA<ValidationFailure>());

      final intoGrandchild = await useCases.move(
        type: EntityType.folder,
        id: a.id,
        targetFolderId: c.id,
      );
      expect(intoGrandchild.failureOrNull, isA<ValidationFailure>());

      final valid = await useCases.move(
        type: EntityType.folder,
        id: c.id,
        targetFolderId: a.id,
      );
      expect(valid.isOk, isTrue);
      expect(vault.folders[c.id]!.parentId, a.id);
    });

    test('moving to root is allowed', () async {
      final a = (await useCases.createFolder(name: 'A')).getOrThrow();
      final b = (await useCases.createFolder(
        name: 'B',
        parentId: a.id,
      )).getOrThrow();
      final result = await useCases.move(
        type: EntityType.folder,
        id: b.id,
        targetFolderId: null,
      );
      expect(result.isOk, isTrue);
      expect(vault.folders[b.id]!.parentId, isNull);
    });

    test('notes are not handled here', () async {
      final result = await useCases.move(
        type: EntityType.note,
        id: 'n',
        targetFolderId: null,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('importDocument', () {
    test('marks cache complete when a local path is given', () async {
      final result = await useCases.importDocument(
        name: 'report.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 10,
        sha256: 'abc',
        localPath: '/cache/report.pdf',
      );
      final doc = result.getOrThrow();
      expect(doc.cacheState, CacheState.complete);
      expect(doc.isUploaded, isFalse);
      expect(vault.documents[doc.id], doc);
    });

    test('rejects negative size', () async {
      final result = await useCases.importDocument(
        name: 'x',
        mimeType: 'text/plain',
        sizeBytes: -1,
        sha256: 'a',
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  test('rename validates and updates timestamps', () async {
    final a = (await useCases.createFolder(name: 'A')).getOrThrow();
    clock.advance(const Duration(minutes: 1));
    final result = await useCases.rename(
      type: EntityType.folder,
      id: a.id,
      name: ' Renamed ',
    );
    expect(result.isOk, isTrue);
    expect(vault.folders[a.id]!.name, 'Renamed');
    expect(vault.folders[a.id]!.updatedAt, clock.now());
  });

  test('delete tombstones', () async {
    final a = (await useCases.createFolder(name: 'A')).getOrThrow();
    await useCases.delete(type: EntityType.folder, id: a.id);
    expect(vault.folders[a.id]!.isDeleted, isTrue);
  });
}
