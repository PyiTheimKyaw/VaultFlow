import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vf_ui/vf_ui.dart';

/// Folder contents. `null` [folderId] is the vault root.
class VaultPage extends StatelessWidget {
  const VaultPage({super.key, this.folderId});

  final String? folderId;

  @override
  Widget build(BuildContext context) {
    final isRoot = folderId == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Breadcrumb(folderId: folderId),
        Expanded(
          child: EmptyState(
            key: Key('vault-${folderId ?? 'root'}'),
            icon: Icons.folder_open_outlined,
            title: isRoot ? 'Your vault is empty' : 'Folder $folderId is empty',
            message: 'Files and folders appear here once Phase 2 lands.',
            action: isRoot
                ? FilledButton.tonalIcon(
                    onPressed: () => context.go(AppRoutes.folder('sample')),
                    icon: const Icon(Icons.folder_outlined),
                    label: const Text('Open sample folder'),
                  )
                : OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.vault),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Back to root'),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.folderId});

  final String? folderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VfSpacing.lg,
        vertical: VfSpacing.sm,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: folderId == null
                ? null
                : () => context.go(AppRoutes.vault),
            child: const Text('Vault'),
          ),
          if (folderId != null) ...[
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Text(folderId!, style: theme.textTheme.labelLarge),
          ],
        ],
      ),
    );
  }
}
