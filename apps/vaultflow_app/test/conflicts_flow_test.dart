import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/features/notes/application/note_editor_controller.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';

import 'helpers/pump_app.dart';

/// Seeds a note that was edited here (pending → conflicted) and on the
/// server, exactly as the outbox processor records it.
Future<String> _seedConflict(TestApp app) async {
  final now = DateTime.utc(2026, 9, 8, 10);
  final noteId = VfId.next();
  final notes = DriftNotesRepository(app.db);
  await app.settle(
    notes.createNote(
      Note(
        id: noteId,
        title: 'Plan',
        body: 'mine',
        createdAt: now,
        updatedAt: now,
      ),
    ),
  );
  // Pretend the create synced (v1), then a local edit conflicted with v2.
  await app.settle(
    app.db.outboxDao.remove((await app.outboxEntries()).map((e) => e.id)),
  );
  final repo = DriftSyncRepository(app.db);
  await app.settle(repo.markSynced(EntityType.note, noteId, version: 1));
  await app.settle(repo.markConflicted(EntityType.note, noteId));
  await app.settle(
    repo.recordConflict(
      id: 'conflict-1',
      type: EntityType.note,
      entityId: noteId,
      local: {
        'id': noteId,
        'title': 'Plan',
        'body': 'mine',
        'version': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      remote: {
        'id': noteId,
        'title': 'Plan',
        'body': 'theirs',
        'version': 2,
        'created_at': now.toIso8601String(),
        'updated_at': now.add(const Duration(minutes: 1)).toIso8601String(),
      },
      remoteVersion: 2,
      now: now,
    ),
  );
  return noteId;
}

void main() {
  testApp('badge and settings surface the conflict', (tester) async {
    final app = await TestApp.pump(tester);
    await _seedConflict(app);
    app.go('/settings');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 item edited on two devices'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-sync-badge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync-sheet')), findsOneWidget);
    expect(find.text('1 conflict need attention'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sync-sheet-conflicts')));
    await tester.pumpAndSettle();
    expect(app.location, '/settings/conflicts');
    expect(find.byKey(const Key('conflict-conflict-1')), findsOneWidget);
  });

  testApp('keep theirs replaces the local note', (tester) async {
    final app = await TestApp.pump(
      tester,
      initialLocation: '/settings/conflicts',
    );
    final noteId = await _seedConflict(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conflict-conflict-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflict-resolver')), findsOneWidget);
    expect(find.text('mine'), findsOneWidget);
    expect(find.text('theirs'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resolve-keep-remote')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflicts-empty')), findsOneWidget);
    final note = await app.settle(DriftNotesRepository(app.db).getNote(noteId));
    expect(note!.body, 'theirs');
    expect(note.version, 2);
    expect(note.syncStatus, SyncStatus.synced);
  });

  testApp('keep both keeps theirs and copies mine', (tester) async {
    final app = await TestApp.pump(
      tester,
      initialLocation: '/settings/conflicts',
    );
    await _seedConflict(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conflict-conflict-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resolve-keep-both')));
    await tester.pumpAndSettle();
    final notes = await app.notes();
    expect(notes, hasLength(2));
    expect(notes.map((n) => n.body).toSet(), {'mine', 'theirs'});
    expect(
      notes.firstWhere((n) => n.body == 'mine').title,
      startsWith('Plan (Conflicted copy'),
    );
    expect(await app.outboxCount(), 1, reason: 'copy is queued for push');
  });

  testApp('keep mine re-bases and queues an update', (tester) async {
    final app = await TestApp.pump(
      tester,
      initialLocation: '/settings/conflicts',
    );
    final noteId = await _seedConflict(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conflict-conflict-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resolve-keep-local')));
    await tester.pumpAndSettle();
    final note = await app.settle(DriftNotesRepository(app.db).getNote(noteId));
    expect(note!.body, 'mine');
    expect(note.version, 2);
    expect(note.syncStatus, SyncStatus.pending);
    final queued = (await app.outboxEntries()).single;
    expect(queued.op, SyncOp.update);
    expect(queued.baseVersion, 2);
  });

  testApp('the note editor shows a banner with a resolve action', (
    tester,
  ) async {
    final app = await TestApp.pump(tester);
    final noteId = await _seedConflict(app);
    app.go('/notes/$noteId');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-conflict-banner')), findsOneWidget);
    expect(find.text('mine'), findsOneWidget);
    await tester.tap(find.byKey(const Key('note-resolve')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflict-resolver')), findsOneWidget);

    // Keep theirs: the open editor must show the new text without leaving.
    await tester.tap(find.byKey(const Key('resolve-keep-remote')));
    await tester.pumpAndSettle();
    expect(app.location, '/notes/$noteId');
    expect(find.byKey(const Key('note-conflict-banner')), findsNothing);
    expect(find.text('theirs'), findsOneWidget);
    expect(find.text('mine'), findsNothing);
    final body = tester.widget<TextField>(find.byKey(const Key('note-body')));
    expect(body.controller!.text, 'theirs');
  });

  testApp('resolving after typing in this session updates the open editor', (
    tester,
  ) async {
    // Field report: the user typed in this editor (autosaved), the push then
    // conflicted, and resolving from the banner must refresh the fields.
    final app = await TestApp.pump(tester, initialLocation: '/notes');
    await tester.tap(find.byKey(const Key('notes-new')));
    await tester.pumpAndSettle();
    final noteId = app.location.split('/').last;
    await tester.enterText(find.byKey(const Key('note-body')), 'mine v2');
    await tester.pump(NoteEditorController.debounce);
    await tester.pumpAndSettle();

    // The push conflicts: the processor records the conflict and flags the
    // note while the editor stays open.
    final now = DateTime.utc(2026, 9, 8, 12);
    final repo = DriftSyncRepository(app.db);
    await app.settle(
      app.db.outboxDao.remove((await app.outboxEntries()).map((e) => e.id)),
    );
    await app.settle(
      repo.recordConflict(
        id: 'conflict-2',
        type: EntityType.note,
        entityId: noteId,
        local: {'id': noteId, 'title': '', 'body': 'mine v2', 'version': 0},
        remote: {
          'id': noteId,
          'title': '',
          'body': 'theirs',
          'version': 2,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        remoteVersion: 2,
        now: now,
      ),
    );
    await app.settle(repo.markConflicted(EntityType.note, noteId));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-conflict-banner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('note-resolve')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resolve-keep-remote')));
    await tester.pumpAndSettle();
    final body = tester.widget<TextField>(find.byKey(const Key('note-body')));
    expect(body.controller!.text, 'theirs');
    expect(find.byKey(const Key('note-conflict-banner')), findsNothing);
  });

  testApp('external changes do not overwrite unsaved typing', (tester) async {
    final app = await TestApp.pump(tester);
    final noteId = await _seedConflict(app);
    app.go('/notes/$noteId');
    await tester.pumpAndSettle();
    // Start typing (not yet saved: debounce has not elapsed).
    await tester.enterText(find.byKey(const Key('note-body')), 'mine, edited');
    await tester.pump();
    // Something else changes the stored note underneath.
    await app.settle(
      DriftNotesRepository(app.db).saveNote(
        noteId,
        title: 'Plan',
        body: 'from elsewhere',
        now: DateTime.utc(2026, 9, 8, 11),
      ),
    );
    await tester.pump();
    final body = tester.widget<TextField>(find.byKey(const Key('note-body')));
    expect(body.controller!.text, 'mine, edited', reason: 'typing wins');
    // Let the autosave debounce fire so no timer outlives the test.
    await tester.pump(NoteEditorController.debounce);
    await tester.pumpAndSettle();
  });
}
