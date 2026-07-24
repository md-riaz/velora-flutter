import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_status.dart';

/// How a [VeloraBadge] fills its background.
enum VeloraBadgeStyle {
  /// A solid fill in the status color, with the status's "on" color for
  /// text. High contrast — use for counts and prominent status pills.
  solid,

  /// A soft, tinted fill (the status color at low opacity) with the status
  /// color itself for text. Lower contrast — use for inline status labels
  /// where a solid pill would be too loud.
  soft,
}

/// A small, pill-shaped status label — a count, a state ("Active", "Pending"),
/// or a tag.
///
/// Its colors come from a [VeloraStatus] resolved against the theme (see
/// [VeloraStatusResolver]), and its shape/spacing from [VeloraTokens]
/// ([VeloraTokens.radiusPill], [VeloraTokens.spacingSm]). Choose [solid] for a
/// filled pill or [soft] for a tinted one via [style].
class VeloraBadge extends StatelessWidget {
  /// The badge's text.
  final String label;

  /// The semantic status that determines the badge's color. Defaults to
  /// [VeloraStatus.info].
  final VeloraStatus status;

  /// Whether the badge is [VeloraBadgeStyle.solid] or [VeloraBadgeStyle.soft].
  /// Defaults to soft.
  final VeloraBadgeStyle style;

  /// An optional icon shown before the label.
  final IconData? icon;

  /// Creates a Velora badge.
  const VeloraBadge({
    super.key,
    required this.label,
    this.status = VeloraStatus.info,
    this.style = VeloraBadgeStyle.soft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final colors = status.colors(context);

    final Color background;
    final Color foreground;
    switch (style) {
      case VeloraBadgeStyle.solid:
        background = colors.color;
        foreground = colors.onColor;
      case VeloraBadgeStyle.soft:
        background = colors.color.withValues(alpha: 0.14);
        foreground = colors.color;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm,
        vertical: tokens.spacingXs / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            SizedBox(width: tokens.spacingXs),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
