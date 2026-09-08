import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflict_resolver_sheet.dart';
import 'package:vaultflow_app/features/notes/application/note_editor_controller.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vaultflow_app/features/vault/presentation/dialogs.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Markdown editor with debounced autosave and a preview toggle.
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({required this.noteId, super.key});

  final String noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  /// Text last written into the controllers from the database, used to
  /// tell external changes apart from the user's own typing.
  String? _seededTitle;
  String? _seededBody;
  bool _preview = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Mirrors the stored note into the fields.
  ///
  /// The stored note arrives on every change, including our own autosaves.
  /// [_seededTitle]/[_seededBody] track the last stored text the editor has
  /// acknowledged, so the cases can be told apart:
  /// * first load → seed;
  /// * stored text equals the fields → our own save round-tripped; move the
  ///   baseline forward;
  /// * stored text equals the baseline → nothing new from outside;
  /// * otherwise something else changed the note (conflict resolution, a
  ///   pulled edit): apply it unless the user has unsaved typing.
  void _seed(Note note) {
    final firstLoad = _seededTitle == null;
    final matchesFields = note.title == _title.text && note.body == _body.text;
    if (!firstLoad && matchesFields) {
      _seededTitle = note.title;
      _seededBody = note.body;
      return;
    }
    final unchangedInDb =
        note.title == _seededTitle && note.body == _seededBody;
    final userIsTyping =
        !firstLoad &&
        (_title.text != _seededTitle || _body.text != _seededBody);
    if (!firstLoad && (unchangedInDb || userIsTyping)) return;
    _seededTitle = note.title;
    _seededBody = note.body;
    _title.value = _title.value.copyWith(
      text: note.title,
      selection: TextSelection.collapsed(offset: note.title.length),
    );
    _body.value = _body.value.copyWith(
      text: note.body,
      selection: TextSelection.collapsed(offset: note.body.length),
    );
  }

  void _changed() => ref
      .read(noteEditorControllerProvider(widget.noteId).notifier)
      .onChanged(title: _title.text, body: _body.text);

  Future<void> _delete(Note note) async {
    final confirmed = await showDeleteDialog(
      context,
      itemName: note.title.isEmpty ? 'Untitled note' : note.title,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(notesUseCasesProvider).delete(note.id);
    if (!mounted) return;
    if (reportResult(context, result)) context.go(AppRoutes.notes);
  }

  Future<void> _move(Note note) async {
    final target = await showMoveDialog(context, title: 'Move note to…');
    if (target == null || !mounted) return;
    final result = await ref
        .read(notesUseCasesProvider)
        .move(id: note.id, targetFolderId: target.folderId);
    if (mounted) reportResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final editor = ref.watch(noteEditorControllerProvider(widget.noteId));
    final theme = Theme.of(context);

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load note',
        message: '$e',
      ),
      data: (note) {
        final hasOpenConflict = (ref.watch(conflictsProvider).value ?? const [])
            .any((c) => c.entityId == widget.noteId);
        if (note == null || note.isDeleted) {
          return EmptyState(
            key: const Key('note-missing'),
            icon: Icons.note_alt_outlined,
            title: 'Note not found',
            message: 'It may have been deleted on another device.',
            action: FilledButton.tonal(
              onPressed: () => context.go(AppRoutes.notes),
              child: const Text('Back to notes'),
            ),
          );
        }
        _seed(note);
        return Column(
          key: Key('note-${note.id}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VfSpacing.sm,
                vertical: VfSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to notes',
                    onPressed: () async {
                      await ref
                          .read(
                            noteEditorControllerProvider(widget.noteId)
                                .notifier,
                          )
                          .flush();
                      if (context.mounted) context.go(AppRoutes.notes);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('note-title'),
                      controller: _title,
                      onChanged: (_) => _changed(),
                      style: theme.textTheme.titleLarge,
                      decoration: const InputDecoration(
                        hintText: 'Untitled note',
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  Text(
                    editor.label,
                    key: const Key('save-status'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: editor.status == SaveStatus.error
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: VfSpacing.sm),
                  SyncStatusBadge(
                    status: badgeFor(note.syncStatus),
                    compact: true,
                  ),
                  IconButton(
                    key: const Key('note-preview'),
                    tooltip: _preview ? 'Edit' : 'Preview',
                    isSelected: _preview,
                    icon: Icon(
                      _preview
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _preview = !_preview),
                  ),
                  PopupMenuButton<String>(
                    key: const Key('note-menu'),
                    onSelected: (v) => unawaited(switch (v) {
                      'move' => _move(note),
                      'delete' => _delete(note),
                      _ => Future<void>.value(),
                    }),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'move', child: Text('Move to…')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            if (note.syncStatus == SyncStatus.conflicted || hasOpenConflict)
              MaterialBanner(
                key: const Key('note-conflict-banner'),
                leading: const Icon(Icons.warning_amber_rounded),
                content: const Text(
                  'This note was also edited on another device.',
                ),
                actions: [
                  TextButton(
                    key: const Key('note-resolve'),
                    onPressed: () async {
                      final conflicts =
                          ref.read(conflictsProvider).value ?? const [];
                      final match = conflicts
                          .where((c) => c.entityId == note.id)
                          .firstOrNull;
                      if (match != null && context.mounted) {
                        await showConflictResolverSheet(context, match);
                      }
                    },
                    child: const Text('Resolve'),
                  ),
                ],
              ),
            Expanded(
              child: _preview
                  ? Markdown(
                      key: const Key('note-markdown'),
                      data: _body.text.isEmpty
                          ? '_Nothing to preview._'
                          : _body.text,
                      selectable: true,
                    )
                  : TextField(
                      key: const Key('note-body'),
                      controller: _body,
                      onChanged: (_) => _changed(),
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'Write in Markdown…',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: VfSpacing.pagePadding,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
