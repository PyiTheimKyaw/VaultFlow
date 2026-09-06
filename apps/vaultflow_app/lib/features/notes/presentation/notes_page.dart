import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vf_ui/vf_ui.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      key: const Key('notes-list'),
      icon: Icons.sticky_note_2_outlined,
      title: 'No notes yet',
      message: 'Markdown notes with offline autosave arrive in Phase 2.',
      action: FilledButton.tonalIcon(
        onPressed: () => context.go(AppRoutes.note('sample')),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Open sample note'),
      ),
    );
  }
}
