import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/notes/application/note_editor_controller.dart';

import 'helpers/pump_app.dart';

void main() {
  testApp('typing autosaves after the debounce and shows status', (
    tester,
  ) async {
    final app = await TestApp.pump(tester, initialLocation: '/notes');
    await tester.tap(find.byKey(const Key('notes-new')));
    await tester.pumpAndSettle();
    expect(app.location, startsWith('/notes/'));
    final noteId = app.location.split('/').last;

    await tester.enterText(find.byKey(const Key('note-title')), 'Plan');
    await tester.enterText(
      find.byKey(const Key('note-body')),
      '# Heading\n\nFirst line',
    );
    await tester.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);

    // Nothing is written before the debounce elapses.
    var note = await app.container
        .read(notesRepositoryProvider)
        .getNote(noteId);
    expect(note!.title, '');

    await tester.pump(NoteEditorController.debounce);
    await tester.pumpAndSettle();
    note = await app.container.read(notesRepositoryProvider).getNote(noteId);
    expect(note!.title, 'Plan');
    expect(note.body, '# Heading\n\nFirst line');
    expect(find.text('Saved'), findsOneWidget);

    // Preview renders the Markdown.
    await tester.tap(find.byKey(const Key('note-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-markdown')), findsOneWidget);
    expect(find.text('Heading'), findsOneWidget);

    // Back to the list: the note shows its title and preview line.
    await tester.tap(find.byTooltip('Back to notes'));
    await tester.pumpAndSettle();
    expect(app.location, '/notes');
    expect(find.text('Plan'), findsOneWidget);
    expect(find.textContaining('# Heading'), findsOneWidget);
  });

  testApp('leaving the editor flushes a pending edit', (tester) async {
    final app = await TestApp.pump(tester, initialLocation: '/notes');
    await tester.tap(find.byKey(const Key('notes-new')));
    await tester.pumpAndSettle();
    final noteId = app.location.split('/').last;

    await tester.enterText(find.byKey(const Key('note-body')), 'quick');
    await tester.pump();
    await tester.tap(find.byTooltip('Back to notes'));
    await tester.pumpAndSettle();

    final note = await app.container
        .read(notesRepositoryProvider)
        .getNote(noteId);
    expect(note!.body, 'quick');
  });

  testApp('deleting from the editor returns to the list', (tester) async {
    final app = await TestApp.pump(tester, initialLocation: '/notes');
    await tester.tap(find.byKey(const Key('notes-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();
    expect(app.location, '/notes');
    expect(find.byKey(const Key('notes-empty')), findsOneWidget);
  });
}
