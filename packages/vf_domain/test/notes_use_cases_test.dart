import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

import 'fakes.dart';

void main() {
  late FakeVaultRepository vault;
  late FakeNotesRepository notes;
  late FakeClock clock;
  late NotesUseCases useCases;

  setUp(() {
    vault = FakeVaultRepository();
    notes = FakeNotesRepository();
    clock = FakeClock(DateTime.utc(2026, 9, 6));
    useCases = NotesUseCases(
      notes: notes,
      vault: vault,
      clock: clock,
      newId: () => 'n1',
    );
  });

  test('create makes an empty note in the root', () async {
    final note = (await useCases.create()).getOrThrow();
    expect(note.id, 'n1');
    expect(note.title, '');
    expect(note.body, '');
    expect(note.folderId, isNull);
    expect(notes.notes['n1'], note);
  });

  test('create rejects unknown folder', () async {
    final result = await useCases.create(folderId: 'nope');
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('save is a no-op when nothing changed', () async {
    await useCases.create(title: 'T');
    final before = notes.saveCalls;
    final result = await useCases.save(id: 'n1', title: 'T ', body: '');
    expect(result.isOk, isTrue);
    expect(notes.saveCalls, before);
  });

  test('save persists edits with the clock time', () async {
    await useCases.create();
    clock.advance(const Duration(seconds: 30));
    final result = await useCases.save(id: 'n1', title: 'Hello', body: 'x');
    expect(result.isOk, isTrue);
    final saved = notes.notes['n1']!;
    expect(saved.title, 'Hello');
    expect(saved.body, 'x');
    expect(saved.updatedAt, clock.now());
  });

  test('save rejects missing or deleted notes and long titles', () async {
    expect(
      (await useCases.save(id: 'zzz', title: '', body: '')).failureOrNull,
      isA<NotFoundFailure>(),
    );
    await useCases.create();
    expect(
      (await useCases.save(id: 'n1', title: 'x' * 300, body: '')).failureOrNull,
      isA<ValidationFailure>(),
    );
    await useCases.delete('n1');
    expect(
      (await useCases.save(id: 'n1', title: 'a', body: '')).failureOrNull,
      isA<NotFoundFailure>(),
    );
  });

  test('search ignores blank queries', () async {
    await useCases.create(title: 'Groceries');
    expect((await useCases.search('   ')).getOrThrow(), isEmpty);
    expect((await useCases.search('groc')).getOrThrow(), hasLength(1));
  });

  test('preview returns the first non-empty body line', () {
    final note = Note(
      id: 'x',
      title: '',
      body: '\n\n  first line  \nsecond',
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
    expect(note.preview, 'first line');
  });
}
