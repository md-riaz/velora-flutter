import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_status.dart';

/// An inline, semantic message banner — a success confirmation, a caution, an
/// informational note, or an error.
///
/// Its accent color and default icon come from a [VeloraStatus] resolved
/// against the theme (see [VeloraStatusResolver]); its layout, radius, and
/// spacing come from [VeloraTokens]. The banner uses a soft tinted background
/// with a leading colored icon and a colored left accent bar so it reads as
/// "this level of message" at a glance without shouting.
///
/// Pass an optional [title] for a bolded heading above [message], and an
/// optional [onClose] to show a dismiss button (the widget doesn't manage its
/// own visibility — the caller removes it from the tree in response).
class VeloraAlert extends StatelessWidget {
  /// The alert's body text.
  final String message;

  /// The semantic level of the alert. Defaults to [VeloraStatus.info].
  final VeloraStatus status;

  /// An optional bold heading shown above [message].
  final String? title;

  /// Overrides the leading glyph. Omit to use the default icon for [status]
  /// (see [VeloraStatusResolver.icon]).
  final IconData? icon;

  /// If non-null, a trailing close button is shown and this is called when it
  /// is tapped. The alert does not hide itself — the caller decides.
  final VoidCallback? onClose;

  /// Creates a Velora alert.
  const VeloraAlert({
    super.key,
    required this.message,
    this.status = VeloraStatus.info,
    this.title,
    this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final colors = status.colors(context);
    final radius = BorderRadius.circular(tokens.radiusMd);

    return Container(
      decoration: BoxDecoration(
        color: colors.color.withValues(alpha: 0.10),
        borderRadius: radius,
        border: Border(
          left: BorderSide(color: colors.color, width: 4),
        ),
      ),
      padding: EdgeInsets.all(tokens.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? status.icon, color: colors.color, size: 20),
          SizedBox(width: tokens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: tokens.spacingXs),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            InkResponse(
              onTap: onClose,
              radius: 18,
              child: Padding(
                padding: EdgeInsets.only(left: tokens.spacingSm),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
