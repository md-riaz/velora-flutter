import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';

/// A centered placeholder for "nothing here yet" screens — an empty list, no
/// search results, a fresh inbox.
///
/// Shows a large muted [icon], a bold [title], an optional supporting
/// [message], and an optional [action] widget (typically a Material widget) to
/// give the user a way forward. Spacing comes from [DesignTokens] so empty
/// states across the app share the same rhythm.
class EmptyState extends StatelessWidget {
  /// The illustrative icon shown above the text.
  final IconData icon;

  /// The bold headline (e.g. "No messages yet").
  final String title;

  /// Optional supporting text below the title.
  final String? message;

  /// Optional call-to-action widget below the text (e.g. a Material widget).
  final Widget? action;

  /// Creates a Velora empty state.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: tokens.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
            ),
            if (message != null) ...[
              SizedBox(height: tokens.spacingSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: tokens.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
