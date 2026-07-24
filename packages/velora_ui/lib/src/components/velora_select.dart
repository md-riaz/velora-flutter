import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A single option in a [VeloraSelect].
@immutable
class VeloraSelectOption<T> {
  /// The value chosen when this option is picked.
  final T value;

  /// The option's display label.
  final String label;

  /// Creates a select option.
  const VeloraSelectOption({required this.value, required this.label});
}

/// A token-driven dropdown/select field.
///
/// A thin wrapper over [DropdownButtonFormField] that matches
/// [VeloraTextField]'s decoration (same token radius, same scheme border
/// colors, same error styling). Controlled: pass [value] and [onChanged].
/// Bind [errorText] to your form controller's per-field error.
class VeloraSelect<T> extends StatelessWidget {
  /// The available options.
  final List<VeloraSelectOption<T>> options;

  /// The currently selected value (null shows [hint]).
  final T? value;

  /// Called with the chosen value. Null renders disabled.
  final ValueChanged<T?>? onChanged;

  /// Floating label.
  final String? label;

  /// Placeholder shown when nothing is selected.
  final String? hint;

  /// Validation error text; drives the error state when non-null.
  final String? errorText;

  /// A leading icon inside the field.
  final IconData? prefixIcon;

  /// Creates a Velora select field.
  const VeloraSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusMd);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: radius,
      hint: hint == null ? null : Text(hint!),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option.value,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacingMd,
          vertical: tokens.spacingMd,
        ),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    );
  }
}
