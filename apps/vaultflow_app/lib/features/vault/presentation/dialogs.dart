import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Asks for a name; returns `null` when cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(
      title: title,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('name-field'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('name-confirm'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> showDeleteDialog(
  BuildContext context, {
  required String itemName,
  bool isFolder = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete "$itemName"?'),
      content: Text(
        isFolder
            ? 'The folder and everything inside it will be moved to the '
                  'trash on every device.'
            : 'The item will be removed on every device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Picks a destination folder. Returns `MoveTarget` or `null` if cancelled.
Future<MoveTarget?> showMoveDialog(
  BuildContext context, {
  required String title,

  /// Folder ids that cannot be chosen (the moved folder and its subtree).
  Set<String> excluded = const {},
}) {
  return showDialog<MoveTarget>(
    context: context,
    builder: (context) => _MoveDialog(title: title, excluded: excluded),
  );
}

class MoveTarget {
  const MoveTarget(this.folderId);

  /// `null` means the vault root.
  final String? folderId;
}

class _MoveDialog extends ConsumerWidget {
  const _MoveDialog({required this.title, required this.excluded});

  final String title;
  final Set<String> excluded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(allFoldersProvider).value ?? const [];
    final rows = _flatten(folders);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        height: 360,
        child: ListView(
          children: [
            ListTile(
              key: const Key('move-root'),
              leading: const Icon(Icons.home_outlined),
              title: const Text('Vault root'),
              onTap: () => Navigator.of(context).pop(const MoveTarget(null)),
            ),
            for (final row in rows)
              ListTile(
                key: Key('move-${row.folder.id}'),
                enabled: !row.disabled,
                contentPadding: EdgeInsets.only(
                  left: VfSpacing.lg + row.depth * VfSpacing.xl,
                  right: VfSpacing.lg,
                ),
                leading: const Icon(Icons.folder_outlined),
                title: Text(row.folder.name),
                onTap: () =>
                    Navigator.of(context).pop(MoveTarget(row.folder.id)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<_TreeRow> _flatten(List<Folder> folders) {
    final byParent = <String?, List<Folder>>{};
    for (final f in folders) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }
    final rows = <_TreeRow>[];
    void visit(String? parent, int depth, bool parentDisabled) {
      for (final f in byParent[parent] ?? const <Folder>[]) {
        final disabled = parentDisabled || excluded.contains(f.id);
        rows.add(_TreeRow(f, depth, disabled));
        visit(f.id, depth + 1, disabled);
      }
    }

    visit(null, 0, false);
    return rows;
  }
}

class _TreeRow {
  const _TreeRow(this.folder, this.depth, this.disabled);
  final Folder folder;
  final int depth;
  final bool disabled;
}
