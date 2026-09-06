import 'package:flutter/material.dart';
import 'package:vf_ui/src/tokens/vf_spacing.dart';

/// Centered placeholder for empty lists, missing items and unbuilt screens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Optional call to action, typically a [FilledButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: VfSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: VfSpacing.xxxl,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: VfSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: VfSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: VfSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
