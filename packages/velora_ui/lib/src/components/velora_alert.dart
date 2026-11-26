import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';
import 'velora_status.dart';

/// An inline, semantic message banner — a success confirmation, a caution, an
/// informational note, or an error.
///
/// Its accent color and default icon come from a [StatusTone] resolved
/// against the theme (see [StatusTone]); its layout, radius, and
/// spacing come from [DesignTokens]. The banner uses a soft tinted background
/// with a leading colored icon and a colored left accent bar so it reads as
/// "this level of message" at a glance without shouting.
///
/// Pass an optional [title] for a bolded heading above [message], and an
/// optional [onClose] to show a dismiss button (the widget doesn't manage its
/// own visibility — the caller removes it from the tree in response).
class InlineAlert extends StatelessWidget {
  /// The alert's body text.
  final String message;

  /// The semantic level of the alert. Defaults to [StatusTone.info].
  final StatusTone status;

  /// An optional bold heading shown above [message].
  final String? title;

  /// Overrides the leading glyph. Omit to use the default icon for [status]
  /// (see [StatusTone.icon]).
  final IconData? icon;

  /// If non-null, a trailing close button is shown and this is called when it
  /// is tapped. The alert does not hide itself — the caller decides.
  final VoidCallback? onClose;

  /// Creates a Velora alert.
  const InlineAlert({
    super.key,
    required this.message,
    this.status = StatusTone.info,
    this.title,
    this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = StatusColors.of(context).forTone(status);
    final radius = BorderRadius.circular(tokens.radiusLg);

    return Container(
      decoration: BoxDecoration(
        color: colors.color.withValues(alpha: 0.10),
        borderRadius: radius,
        border: Border(left: BorderSide(color: colors.color, width: 4)),
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
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: tokens.spacingXs),
                ],
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            Semantics(
              button: true,
              label: 'Dismiss',
              child: InkResponse(
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
            ),
        ],
      ),
    );
  }
}
