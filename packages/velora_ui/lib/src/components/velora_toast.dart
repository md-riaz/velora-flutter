import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_status.dart';

/// Static helpers for showing transient feedback via [ScaffoldMessenger].
///
/// [VeloraToast] has no instantiable widget of its own — it wraps
/// [ScaffoldMessenger.showSnackBar] with Velora's chrome. The snack bar
/// itself (floating behavior, radius) comes from the active theme's
/// `SnackBarThemeData` (set up by `buildVeloraTheme`); this helper only
/// builds the content: an optional leading status icon, the [message], and
/// an optional trailing action.
abstract final class VeloraToast {
  /// Shows a toast (snack bar) with [message], replacing any toast already
  /// showing on the nearest [ScaffoldMessenger].
  ///
  /// When [status] is given, a leading icon (its default status icon, or
  /// [icon] to override it) is tinted with the status's color; with no
  /// [status], [icon] (if given) renders in the theme's neutral content
  /// color. Pass [actionLabel]/[onAction] to add a trailing
  /// [SnackBarAction]. [duration] controls how long the toast stays visible
  /// before auto-dismissing (default 4 seconds).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    VeloraStatus? status,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final tokens = context.veloraTokens;
    // `icon` is documented as an override, so it wins over the status's
    // default glyph (matching VeloraAlert); the tint still comes from
    // `status` either way.
    final leadingIcon = icon ?? status?.icon;
    final iconColor = status?.colors(context).color;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: iconColor, size: 20),
              SizedBox(width: tokens.spacingSm),
            ],
            Flexible(child: Text(message)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
  }
}
