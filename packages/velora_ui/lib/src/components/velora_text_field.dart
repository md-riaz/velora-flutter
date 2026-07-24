import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/velora_tokens_context.dart';

/// A token-driven single- or multi-line text input.
///
/// It's a thin, controlled wrapper over Material's [TextField] that derives
/// its border radius from [VeloraTokens.radiusMd] and its colors from the
/// theme's [ColorScheme] (outline when idle, primary when focused, error when
/// [errorText] is set). Pass [errorText] to drive the error state — the same
/// `String?` a `VeloraFormController` field validator returns — so wiring a
/// field to the framework's form layer is just
/// `errorText: controller.errorFor('email')`.
///
/// When [obscureText] is true a show/hide toggle is added as the trailing
/// affordance automatically (unless you supply your own [suffixIcon]).
class VeloraTextField extends StatefulWidget {
  /// The floating label shown above the field when focused/filled.
  final String? label;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// Helper text shown below the field (hidden while [errorText] is set).
  final String? helperText;

  /// Error text shown below the field; when non-null the field renders in its
  /// error state. Bind this to your form controller's per-field error.
  final String? errorText;

  /// An optional external controller. If null, the field manages its own.
  final TextEditingController? controller;

  /// Seed text used only when [controller] is null.
  final String? initialValue;

  /// Called whenever the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (e.g. taps the keyboard action).
  final ValueChanged<String>? onSubmitted;

  /// Obscures the text (passwords). Adds a show/hide toggle unless
  /// [suffixIcon] is provided.
  final bool obscureText;

  /// A leading icon inside the field.
  final IconData? prefixIcon;

  /// A trailing icon inside the field. Overrides the automatic obscure toggle.
  final IconData? suffixIcon;

  /// Called when [suffixIcon] is tapped.
  final VoidCallback? onSuffixTap;

  /// The keyboard type (email, number, ...).
  final TextInputType? keyboardType;

  /// The keyboard action button.
  final TextInputAction? textInputAction;

  /// Whether the field accepts input. Defaults to true.
  final bool enabled;

  /// Whether the field is read-only (focusable/selectable but not editable).
  final bool readOnly;

  /// Whether to focus this field on first build.
  final bool autofocus;

  /// Maximum number of lines. Defaults to 1 (single-line).
  final int? maxLines;

  /// Minimum number of lines for a multi-line field.
  final int? minLines;

  /// Optional max character count (shows Material's counter).
  final int? maxLength;

  /// Input formatters (e.g. digits-only).
  final List<TextInputFormatter>? inputFormatters;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Creates a Velora text field.
  const VeloraTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  State<VeloraTextField> createState() => _VeloraTextFieldState();
}

class _VeloraTextFieldState extends State<VeloraTextField> {
  TextEditingController? _internalController;
  late bool _obscured = widget.obscureText;

  TextEditingController get _controller =>
      widget.controller ??
      (_internalController ??= TextEditingController(text: widget.initialValue));

  @override
  void didUpdateWidget(VeloraTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resync the reveal state if the parent rebuilds with a different
    // obscureText (the initializer only seeds it once at construction).
    if (widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

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

    // Build the trailing affordance: an obscure toggle for password fields,
    // otherwise the caller's suffixIcon (if any).
    Widget? suffix;
    if (widget.obscureText && widget.suffixIcon == null) {
      suffix = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        tooltip: _obscured ? 'Show' : 'Hide',
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    } else if (widget.suffixIcon != null) {
      suffix = IconButton(
        icon: Icon(widget.suffixIcon),
        onPressed: widget.onSuffixTap,
      );
    }

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: suffix,
        filled: true,
        fillColor: widget.enabled
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.15),
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
