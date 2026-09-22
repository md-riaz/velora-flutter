import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_button.dart';
import 'velora_status.dart';

/// A token-styled dialog surface — a modal message, confirmation, or custom
/// form hosted inside Velora's dialog chrome.
///
/// The surface itself (radius, background, elevation) comes from the active
/// theme's `DialogThemeData` (set up by `buildVeloraTheme`); this widget only
/// lays out the content: an optional leading [icon] (or the default icon for
/// [status]) beside [title], [message] body copy, an optional custom
/// [content] widget, and a right-aligned, wrapping row of [actions].
///
/// When both [message] and [content] are given, [message] renders above
/// [content] — e.g. a short explanation above a form.
///
/// Most callers won't build [VeloraDialog] directly — use the [show] and
/// [confirm] static helpers, which handle [showDialog] plumbing.
class VeloraDialog extends StatelessWidget {
  /// The dialog's heading, shown in `textTheme.titleLarge`.
  final String? title;

  /// The dialog's body copy, shown in `textTheme.bodyMedium` above
  /// [content] (if both are given).
  final String? message;

  /// A custom body widget, rendered below [message] (if given). Use this
  /// for a dialog that hosts a form or other bespoke content instead of — or
  /// alongside — plain [message] text.
  final Widget? content;

  /// The dialog's action buttons (typically [VeloraButton]s), laid out in a
  /// right-aligned, wrapping row with token-spaced gaps.
  final List<Widget>? actions;

  /// Overrides the leading glyph shown beside [title]. Omit to use the
  /// default icon for [status] (see [VeloraStatusResolver.icon]), or omit
  /// both for no leading icon.
  final IconData? icon;

  /// An optional semantic accent for the leading icon/title (e.g.
  /// [VeloraStatus.error] for a destructive confirmation).
  final VeloraStatus? status;

  /// Creates a Velora dialog surface. Prefer [VeloraDialog.show] or
  /// [VeloraDialog.confirm] over constructing and showing this directly.
  const VeloraDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions,
    this.icon,
    this.status,
  });

  /// Shows a [VeloraDialog] via [showDialog] and returns its popped value.
  ///
  /// [barrierDismissible] controls whether tapping outside the dialog pops
  /// it with a `null` result (default `true`).
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    IconData? icon,
    VeloraStatus? status,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => VeloraDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        icon: icon,
        status: status,
      ),
    );
  }

  /// Shows a two-button confirm/cancel [VeloraDialog] and returns whether
  /// the destructive/confirming action was chosen.
  ///
  /// The dialog's actions are a ghost [cancelLabel] button (pops `false`)
  /// and a primary — or [VeloraButtonVariant.danger] when [destructive] is
  /// true — [confirmLabel] button (pops `true`). Returns `null` if the
  /// dialog is dismissed without either button being tapped.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return show<bool>(
      context,
      title: title,
      message: message,
      status: destructive ? VeloraStatus.error : null,
      actions: [
        VeloraButton(
          label: cancelLabel,
          variant: VeloraButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        VeloraButton(
          label: confirmLabel,
          variant: destructive
              ? VeloraButtonVariant.danger
              : VeloraButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasHeader = title != null || icon != null || status != null;
    final accentColor = status?.colors(context).color ?? scheme.onSurface;
    final headerIcon = icon ?? status?.icon;

    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (headerIcon != null) ...[
                    Icon(headerIcon, color: accentColor, size: 24),
                    SizedBox(width: tokens.spacingSm),
                  ],
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: textTheme.titleLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: tokens.spacingMd),
            ],
            if (message != null)
              Text(
                message!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (message != null && content != null)
              SizedBox(height: tokens.spacingMd),
            ?content,
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: tokens.spacingLg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: tokens.spacingSm,
                runSpacing: tokens.spacingSm,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
