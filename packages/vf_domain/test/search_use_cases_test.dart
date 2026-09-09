import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

import 'fakes.dart';

void main() {
  late FakeVaultRepository vault;
  late FakeNotesRepository notes;
  late SearchUseCases search;

  Folder folder(String name) => Folder(
    id: VfId.next(),
    name: name,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUp(() {
    vault = FakeVaultRepository();
    notes = FakeNotesRepository();
    search = SearchUseCases(vault: vault, notes: notes);
  });

  test(
    'blank queries return nothing without touching the repositories',
    () async {
      vault.folders['a'] = folder('anything');
      final result = await search.search('   ');
      expect(result.getOrThrow().isEmpty, isTrue);
    },
  );

  test('combines name matches with note full text', () async {
    final f = folder('Tax 2026');
    vault.folders[f.id] = f;
    notes.notes['n'] = Note(
      id: 'n',
      title: 'Groceries',
      body: 'remember the tax receipt',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final hits = (await search.search('tax')).getOrThrow();
    expect(hits.folders.single.id, f.id);
    expect(hits.notes.single.id, 'n');
    expect(hits.documents, isEmpty);
  });
}
