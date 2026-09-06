import 'package:flutter_test/flutter_test.dart';
import 'package:vf_database/vf_database.dart';

import 'helpers.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());
  tearDown(() => h.close());

  test('full-text search matches title and body with prefixes', () async {
    await h.notes.createNote(h.note('Grocery list', body: 'milk, eggs'));
    await h.notes.createNote(h.note('Meeting', body: 'discuss the budget'));
    await h.notes.createNote(h.note('Café', body: 'résumé draft'));

    expect((await h.notes.search('groc')).single.title, 'Grocery list');
    expect((await h.notes.search('budget')).single.title, 'Meeting');
    expect((await h.notes.search('milk eggs')).single.title, 'Grocery list');
    // Diacritics are folded.
    expect((await h.notes.search('cafe')).single.title, 'Café');
    expect((await h.notes.search('resume')).single.title, 'Café');
    expect(await h.notes.search('nothing'), isEmpty);
  });

  test('search follows edits and excludes deleted notes', () async {
    final note = h.note('Draft', body: 'alpha');
    await h.notes.createNote(note);
    await h.notes.saveNote(
      note.id,
      title: 'Draft',
      body: 'beta',
      now: h.clock.now(),
    );
    expect(await h.notes.search('alpha'), isEmpty);
    expect(await h.notes.search('beta'), hasLength(1));

    await h.notes.deleteNote(note.id, h.clock.now());
    expect(await h.notes.search('beta'), isEmpty);
  });

  test('FTS operators in user input are neutralised', () async {
    await h.notes.createNote(h.note('x', body: 'plain'));
    expect(NotesDao.toFtsQuery('a OR "b'), '"a"* "OR"* "b"*');
    expect(await h.notes.search('NOT plain'), isEmpty);
    expect(await h.notes.search('plain*'), hasLength(1));
    expect(await h.notes.search('   '), isEmpty);
  });

  test('watchAllNotes orders by most recently updated', () async {
    final old = h.note('old');
    await h.notes.createNote(old);
    h.clock.advance(const Duration(minutes: 1));
    await h.notes.createNote(h.note('new'));
    h.clock.advance(const Duration(minutes: 1));
    await h.notes.saveNote(
      old.id,
      title: 'old',
      body: 'edited',
      now: h.clock.now(),
    );

    final all = await h.notes.watchAllNotes().first;
    expect(all.map((n) => n.title), ['old', 'new']);
  });
}
