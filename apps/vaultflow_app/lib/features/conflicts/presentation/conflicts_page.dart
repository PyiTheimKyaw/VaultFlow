import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflict_resolver_sheet.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/sync/application/sync_coordinator.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// Unresolved sync conflicts.
class ConflictsPage extends ConsumerWidget {
  const ConflictsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(conflictsProvider);
    return conflicts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load conflicts',
        message: '$e',
      ),
      data: (list) => list.isEmpty
          ? const EmptyState(
              key: Key('conflicts-empty'),
              icon: Icons.check_circle_outline,
              title: 'No conflicts',
              message: 'Edits from every device have been merged.',
            )
          : ListView.separated(
              key: const Key('conflicts-list'),
              padding: const EdgeInsets.symmetric(vertical: VfSpacing.sm),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(indent: 72),
              itemBuilder: (context, i) => _ConflictTile(conflict: list[i]),
            ),
    );
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.conflict});

  final Conflict conflict;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('conflict-${conflict.id}'),
      leading: CircleAvatar(
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        child: Icon(iconFor(conflict.entityType)),
      ),
      title: Text(displayName(conflict.localSnapshot, conflict.entityType)),
      subtitle: Text(
        'Edited here and on another device · '
        '${formatRelative(conflict.createdAt)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showConflictResolverSheet(context, conflict),
    );
  }
}

IconData iconFor(EntityType type) => switch (type) {
  EntityType.folder => Icons.folder_outlined,
  EntityType.document => Icons.insert_drive_file_outlined,
  EntityType.note => Icons.sticky_note_2_outlined,
};

/// Name or title from a wire snapshot.
String displayName(Map<String, Object?> snapshot, EntityType type) {
  final raw = type == EntityType.note ? snapshot['title'] : snapshot['name'];
  final text = raw is String ? raw : '';
  if (text.isNotEmpty) return text;
  return type == EntityType.note ? 'Untitled note' : 'Unnamed';
}
