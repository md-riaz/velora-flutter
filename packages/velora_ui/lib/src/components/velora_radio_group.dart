import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A single option in a [VeloraRadioGroup].
@immutable
class VeloraRadioOption<T> {
  /// The value selected when this option is chosen.
  final T value;

  /// The option's label.
  final String label;

  /// Optional secondary line below the label.
  final String? subtitle;

  /// Creates a radio option.
  const VeloraRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

/// A vertical group of single-select radio options.
///
/// Controlled: pass the current [groupValue] and an [onChanged] that fires
/// with the chosen option's value. The radio glyph is drawn with token/scheme
/// colors (rather than Material's [Radio]) so it stays consistent with the kit
/// and independent of SDK radio-API changes. Pass [label] for a group heading
/// and [errorText] for a validation message — the same `String?` a
/// `VeloraFormController` validator returns.
class VeloraRadioGroup<T> extends StatelessWidget {
  /// The available options.
  final List<VeloraRadioOption<T>> options;

  /// The currently selected value (null = nothing selected).
  final T? groupValue;

  /// Called with an option's value when it's tapped. Null renders disabled.
  final ValueChanged<T>? onChanged;

  /// Optional heading shown above the options.
  final String? label;

  /// Optional validation error shown below the options.
  final String? errorText;

  /// Creates a Velora radio group.
  const VeloraRadioGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spacingXs),
        ],
        for (final option in options)
          InkWell(
            onTap: enabled ? () => onChanged!(option.value) : null,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    option.value == groupValue
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: !enabled
                        ? scheme.onSurface.withValues(alpha: 0.38)
                        : option.value == groupValue
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                  SizedBox(width: tokens.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: enabled
                                ? scheme.onSurface
                                : scheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                        if (option.subtitle != null)
                          Text(
                            option.subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
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
            padding: EdgeInsets.only(top: tokens.spacingXs),
            child: Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
