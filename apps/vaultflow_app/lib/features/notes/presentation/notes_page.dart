import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vf_ui/vf_ui.dart';

/// All notes, most recently edited first.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _newNote(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(notesUseCasesProvider).create();
    if (!context.mounted) return;
    if (reportResult(context, result)) {
      context.go(AppRoutes.note(result.getOrThrow().id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(allNotesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('notes-new'),
        onPressed: () => _newNote(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New note'),
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notes',
          message: '$e',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                key: Key('notes-empty'),
                icon: Icons.sticky_note_2_outlined,
                title: 'No notes yet',
                message:
                    'Notes are Markdown, autosave as you type and work '
                    'fully offline.',
              )
            : ListView.separated(
                key: const Key('notes-list'),
                padding: const EdgeInsets.only(top: VfSpacing.sm, bottom: 88),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(indent: 16),
                itemBuilder: (context, i) {
                  final note = list[i];
                  return ListTile(
                    key: Key('note-row-${note.id}'),
                    title: Text(
                      note.title.isEmpty ? 'Untitled note' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.preview.isEmpty
                          ? formatRelative(note.updatedAt)
                          : '${note.preview} · '
                                '${formatRelative(note.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SyncStatusBadge(
                      status: badgeFor(note.syncStatus),
                      compact: true,
                    ),
                    onTap: () => context.go(AppRoutes.note(note.id)),
                  );
                },
              ),
      ),
    );
  }
}
