import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// The visual weight of a [VeloraButton].
enum VeloraButtonVariant {
  /// A solid, high-emphasis button using the theme's primary color. The
  /// default — use it for the single most important action on a screen.
  primary,

  /// A solid, medium-emphasis button using the theme's secondary-container
  /// color. Use it for supporting actions alongside a [primary] one.
  secondary,

  /// A low-emphasis outlined button (transparent fill, primary-colored
  /// border and label). Use it for secondary actions where a solid fill
  /// would compete with the primary button.
  outline,

  /// The lowest-emphasis button (no fill, no border, primary-colored label).
  /// Use it for tertiary actions, toolbar buttons, and inline links.
  ghost,

  /// A solid, high-emphasis destructive button using the theme's error
  /// color. Use it for irreversible actions (delete, remove).
  danger,
}

/// The size of a [VeloraButton], controlling height and horizontal padding.
enum VeloraButtonSize {
  /// A compact button (40px tall) for dense layouts and toolbars.
  small,

  /// The default button height (48px).
  medium,

  /// A large, prominent button (56px) for primary calls to action.
  large,
}

/// A token-driven button with a handful of [VeloraButtonVariant]s and
/// [VeloraButtonSize]s, plus a built-in [loading] state and optional leading
/// [icon].
///
/// It builds on Material's [ButtonStyleButton] machinery (so it gets ripples,
/// focus/hover states, and accessibility for free) but derives all of its
/// colors, radii, and spacing from the active theme's [ColorScheme] and
/// [VeloraTokens] rather than Material's defaults — so a Velora app's buttons
/// stay consistent with the rest of the kit.
///
/// While [loading] is true the label is replaced by a spinner and
/// [onPressed] is suppressed, so a caller can bind it directly to a
/// controller's loading flag (e.g. `loading: controller.isLoading.value`)
/// without also having to null out the callback.
class VeloraButton extends StatelessWidget {
  /// The button's label.
  final String label;

  /// Called when the button is tapped. If null (and not [loading]), the
  /// button renders disabled.
  final VoidCallback? onPressed;

  /// The button's visual weight. Defaults to [VeloraButtonVariant.primary].
  final VeloraButtonVariant variant;

  /// The button's size. Defaults to [VeloraButtonSize.medium].
  final VeloraButtonSize size;

  /// An optional icon shown before the label.
  final IconData? icon;

  /// When true, the label is replaced by a spinner and taps are ignored.
  final bool loading;

  /// When true, the button expands to fill the available horizontal space.
  final bool fullWidth;

  /// Creates a Velora button.
  const VeloraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VeloraButtonVariant.primary,
    this.size = VeloraButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  // Flat, token-rounded heights: comfortably tappable at every size, and a
  // full step apart so `small`/`large` read as distinct from the default.
  double get _height {
    switch (size) {
      case VeloraButtonSize.small:
        return 40;
      case VeloraButtonSize.medium:
        return 48;
      case VeloraButtonSize.large:
        return 56;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    // The ambient, tuned label style — semi-bold with positive tracking —
    // rather than a hardcoded weight/size, so buttons pick up Velora's type
    // scale (and any brand font) automatically.
    final labelStyle =
        Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    // Foreground/background per variant, pulled from the ColorScheme so the
    // button tracks light/dark and any theme override.
    final Color foreground;
    final Color? background;
    final BorderSide? side;
    switch (variant) {
      case VeloraButtonVariant.primary:
        foreground = scheme.onPrimary;
        background = scheme.primary;
        side = null;
      case VeloraButtonVariant.secondary:
        foreground = scheme.onSecondaryContainer;
        background = scheme.secondaryContainer;
        side = null;
      case VeloraButtonVariant.outline:
        foreground = scheme.primary;
        background = Colors.transparent;
        side = BorderSide(color: scheme.outlineVariant);
      case VeloraButtonVariant.ghost:
        foreground = scheme.primary;
        background = Colors.transparent;
        side = null;
      case VeloraButtonVariant.danger:
        foreground = scheme.onError;
        background = scheme.error;
        side = null;
    }

    final horizontalPadding = switch (size) {
      VeloraButtonSize.small => tokens.spacingMd,
      VeloraButtonSize.medium => tokens.spacingLg,
      VeloraButtonSize.large => tokens.spacingXl,
    };

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, _height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return background == Colors.transparent
              ? Colors.transparent
              : scheme.onSurface.withValues(alpha: 0.12);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return foreground;
      }),
      overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: 0.1)),
      side: side == null ? null : WidgetStatePropertyAll(side),
      // Flat — no Material elevation/shadow at any interaction state.
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      textStyle: WidgetStatePropertyAll(labelStyle),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final Widget child;
    if (loading) {
      final spinnerSize = (labelStyle.fontSize ?? 14) + 4;
      // Keep the button's accessible name while the spinner replaces the
      // label text — otherwise a screen reader announces an unnamed button.
      child = Semantics(
        label: label,
        child: SizedBox(
          height: spinnerSize,
          width: spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(foreground),
          ),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: (labelStyle.fontSize ?? 14) + 4),
          SizedBox(width: tokens.spacingSm),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );
    } else {
      child = Text(label, overflow: TextOverflow.ellipsis);
    }

    // While loading, suppress the callback but keep the button looking
    // enabled (a disabled-grey spinner reads as "broken", not "working").
    final effectiveOnPressed = loading ? () {} : onPressed;

    final button = TextButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
