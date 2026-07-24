import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A labeled switch row — a [Switch] with a tappable [label]/[subtitle], laid
/// out as a settings-style row (label on the left, switch on the right).
///
/// Controlled: pass [value] and [onChanged]. Colors come from the theme's
/// [ColorScheme]; spacing from [VeloraTokens]. Set [onChanged] to null to
/// render disabled.
class VeloraSwitch extends StatelessWidget {
  /// Whether the switch is on.
  final bool value;

  /// Called with the new value when toggled. Null renders disabled.
  final ValueChanged<bool>? onChanged;

  /// The primary label.
  final String label;

  /// Optional secondary line below the label.
  final String? subtitle;

  /// Creates a Velora switch row.
  const VeloraSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;

    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacingXs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: tokens.spacingSm),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
