import 'package:flutter/material.dart';
import 'package:vf_ui/src/tokens/vf_colors.dart';
import 'package:vf_ui/src/tokens/vf_spacing.dart';

/// Presentation-level sync state. The sync engine maps its richer state onto
/// one of these values; the badge never depends on domain types.
enum SyncBadgeStatus {
  synced,
  pending,
  syncing,
  conflicted,
  offline,
  error;

  String get label => switch (this) {
    synced => 'Synced',
    pending => 'Pending',
    syncing => 'Syncing',
    conflicted => 'Conflict',
    offline => 'Offline',
    error => 'Sync error',
  };

  IconData get icon => switch (this) {
    synced => Icons.cloud_done_outlined,
    pending => Icons.cloud_upload_outlined,
    syncing => Icons.sync,
    conflicted => Icons.warning_amber_rounded,
    offline => Icons.cloud_off_outlined,
    error => Icons.error_outline,
  };
}

/// Small pill (or bare icon when [compact]) showing a [SyncBadgeStatus].
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    required this.status,
    super.key,
    this.compact = false,
    this.onTap,
  });

  final SyncBadgeStatus status;

  /// Icon only, for app bars and dense list rows.
  final bool compact;
  final VoidCallback? onTap;

  Color _color(VfSemanticColors colors) => switch (status) {
    SyncBadgeStatus.synced => colors.success,
    SyncBadgeStatus.pending => colors.info,
    SyncBadgeStatus.syncing => colors.info,
    SyncBadgeStatus.conflicted => colors.warning,
    SyncBadgeStatus.offline => colors.neutral,
    SyncBadgeStatus.error => colors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context.semanticColors);
    final icon = status == SyncBadgeStatus.syncing
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(status.icon, size: 16, color: color);

    if (compact) {
      return Tooltip(
        message: status.label,
        child: IconButton(
          onPressed: onTap,
          icon: icon,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return Semantics(
      label: 'Sync status: ${status.label}',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VfRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VfSpacing.md,
            vertical: VfSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(VfRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: VfSpacing.sm),
              Text(
                status.label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
