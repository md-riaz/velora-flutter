import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A titled header for a content section — a screen region, a card group, a
/// settings block.
///
/// Shows an emphasized [title], an optional supporting [subtitle] beneath
/// it, and an optional trailing [action] widget (typically a [VeloraButton]
/// with [VeloraButtonVariant.ghost], or a plain "See all" [TextButton])
/// aligned to the header's far side. Spacing comes from [VeloraTokens]; text
/// styles come from the ambient [TextTheme] with [ColorScheme]-driven
/// colors.
class VeloraSectionHeader extends StatelessWidget {
  /// The section's title.
  final String title;

  /// Optional supporting text shown below [title].
  final String? subtitle;

  /// An optional trailing widget, e.g. a "See all" action.
  final Widget? action;

  /// Creates a Velora section header.
  const VeloraSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: tokens.spacingXs / 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(width: tokens.spacingSm),
            action!,
          ],
        ],
      ),
    );
  }
}
