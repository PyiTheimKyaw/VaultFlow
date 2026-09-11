import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/features/shared/formatting.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vaultflow_app/features/vault/application/cache_manager.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_ui/vf_ui.dart';

/// How much the local cache uses and which copies can be dropped.
class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});

  Future<void> _freeUp(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(cacheManagerProvider).evictAll();
    ref.invalidate(cacheUsageProvider);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        reportResult(
          context,
          okVoid,
          successMessage: 'Freed ${formatBytes(value)}',
        );
      case Err():
        reportResult(context, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(cacheUsageProvider);
    return usage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not measure storage',
        message: '$e',
      ),
      data: (u) => ListView(
        key: const Key('storage'),
        padding: VfSpacing.pagePadding,
        children: [
          ListTile(
            key: const Key('storage-total'),
            leading: const Icon(Icons.sd_storage_outlined),
            title: const Text('Local cache'),
            subtitle: Text('${formatBytes(u.totalBytes)} on this device'),
          ),
          ListTile(
            key: const Key('storage-evictable'),
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Copies also on the server'),
            subtitle: Text(
              u.evictable.isEmpty
                  ? 'Nothing to free'
                  : '${u.evictable.length} file'
                        '${u.evictable.length == 1 ? '' : 's'}, '
                        '${formatBytes(u.evictableBytes)}',
            ),
            trailing: FilledButton.tonal(
              key: const Key('storage-free-up'),
              onPressed: u.evictable.isEmpty
                  ? null
                  : () => unawaited(_freeUp(context, ref)),
              child: const Text('Free up space'),
            ),
          ),
          const Divider(),
          for (final doc in u.evictable)
            ListTile(
              key: Key('storage-doc-${doc.id}'),
              dense: true,
              title: Text(doc.name),
              subtitle: Text(formatBytes(doc.sizeBytes)),
              trailing: IconButton(
                key: Key('storage-evict-${doc.id}'),
                tooltip: 'Remove local copy',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () async {
                  final result = await ref
                      .read(cacheManagerProvider)
                      .evict(doc);
                  ref.invalidate(cacheUsageProvider);
                  if (context.mounted) reportResult(context, result);
                },
              ),
            ),
          if (u.evictable.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: VfSpacing.md),
              child: Text(
                'Files you import stay here until they have been uploaded; '
                'downloaded files stay until you remove them or sign out.',
              ),
            ),
        ],
      ),
    );
  }
}
