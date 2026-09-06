import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vf_ui/vf_ui.dart';

class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onPressed: () => context.go(AppRoutes.notes),
                icon: const Icon(Icons.arrow_back),
              ),
              Text('Note $noteId', style: VfTypography.mono),
            ],
          ),
        ),
        Expanded(
          child: EmptyState(
            key: Key('note-$noteId'),
            icon: Icons.edit_note_outlined,
            title: 'Editor placeholder',
            message: 'The Markdown editor arrives in Phase 2.',
          ),
        ),
      ],
    );
  }
}
