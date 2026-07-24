import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A labeled checkbox row — a [Checkbox] plus tappable [label]/[subtitle],
/// so the whole row toggles (not just the 16px box).
///
/// Controlled: pass [value] and [onChanged]. Colors come from the theme's
/// [ColorScheme]; spacing from [VeloraTokens]. Set [onChanged] to null to
/// render disabled.
class VeloraCheckbox extends StatelessWidget {
  /// Whether the box is checked.
  final bool value;

  /// Called with the new value when the row is toggled. Null renders disabled.
  final ValueChanged<bool>? onChanged;

  /// The primary label beside the box.
  final String label;

  /// Optional secondary line below the label.
  final String? subtitle;

  /// Optional per-field error text shown below the row.
  final String? errorText;

  /// Creates a Velora checkbox row.
  const VeloraCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.subtitle,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacingXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: tokens.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spacingXs + 2),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: enabled
                                ? scheme.onSurface
                                : scheme.onSurface.withValues(alpha: 0.38),
                            fontSize: 14,
                          ),
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
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(left: tokens.spacingMd, top: tokens.spacingXs),
            child: Text(
              errorText!,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
