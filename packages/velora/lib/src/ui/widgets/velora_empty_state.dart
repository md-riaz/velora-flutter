import 'package:flutter/material.dart';

/// Standardised empty-state layout used when a list or data view has nothing
/// to show.  Renders a centred column with an icon, title, optional
/// description, and optional CTA button.
///
/// Usage:
/// ```dart
/// Obx(() {
///   if (controller.items.isEmpty) {
///     return VeloraEmptyState(
///       icon: Icons.inbox_outlined,
///       title: 'No notifications',
///       description: 'You're all caught up!',
///     );
///   }
///   return ListView(...);
/// })
/// ```
class VeloraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;

  const VeloraEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.iconSize = 56,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? scheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
