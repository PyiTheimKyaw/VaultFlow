import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_core/vf_core.dart';

part 'note_editor_controller.g.dart';

enum SaveStatus { idle, dirty, saving, saved, error }

class EditorState {
  const EditorState({required this.status, this.error});

  final SaveStatus status;
  final String? error;

  String get label => switch (status) {
    SaveStatus.idle => '',
    SaveStatus.dirty => 'Unsaved changes',
    SaveStatus.saving => 'Saving…',
    SaveStatus.saved => 'Saved',
    SaveStatus.error => 'Save failed: $error',
  };
}

/// Debounced autosave for one note. Edits are held for [debounce] and then
/// written through `NotesUseCases.save`; [flush] writes immediately (used
/// when the editor closes).
@riverpod
class NoteEditorController extends _$NoteEditorController {
  static const Duration debounce = Duration(milliseconds: 800);

  Timer? _timer;
  String? _pendingTitle;
  String? _pendingBody;

  @override
  EditorState build(String noteId) {
    ref.onDispose(() {
      _timer?.cancel();
      // Fire-and-forget: the provider is going away, but the write must
      // still land.
      unawaited(_write());
    });
    return const EditorState(status: SaveStatus.idle);
  }

  void onChanged({required String title, required String body}) {
    _pendingTitle = title;
    _pendingBody = body;
    state = const EditorState(status: SaveStatus.dirty);
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_write()));
  }

  Future<void> flush() async {
    _timer?.cancel();
    await _write();
  }

  Future<void> _write() async {
    final title = _pendingTitle;
    final body = _pendingBody;
    if (title == null || body == null) return;
    _pendingTitle = null;
    _pendingBody = null;

    if (ref.mounted) state = const EditorState(status: SaveStatus.saving);
    final result = await ref
        .read(notesUseCasesProvider)
        .save(id: noteId, title: title, body: body);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const EditorState(status: SaveStatus.saved),
      Err(:final failure) => EditorState(
        status: SaveStatus.error,
        error: failure.message,
      ),
    };
  }
}
