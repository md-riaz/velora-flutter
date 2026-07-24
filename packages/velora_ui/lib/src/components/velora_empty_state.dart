import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A centered placeholder for "nothing here yet" screens — an empty list, no
/// search results, a fresh inbox.
///
/// Shows a large muted [icon], a bold [title], an optional supporting
/// [message], and an optional [action] widget (typically a [VeloraButton]) to
/// give the user a way forward. Spacing comes from [VeloraTokens] so empty
/// states across the app share the same rhythm.
class VeloraEmptyState extends StatelessWidget {
  /// The illustrative icon shown above the text.
  final IconData icon;

  /// The bold headline (e.g. "No messages yet").
  final String title;

  /// Optional supporting text below the title.
  final String? message;

  /// Optional call-to-action widget below the text (e.g. a [VeloraButton]).
  final Widget? action;

  /// Creates a Velora empty state.
  const VeloraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;

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
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: tokens.spacingSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
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
