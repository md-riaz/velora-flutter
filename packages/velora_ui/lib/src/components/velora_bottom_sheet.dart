import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// Static helpers for showing a token-styled modal bottom sheet.
///
/// [VeloraBottomSheet] has no instantiable widget of its own — it wraps
/// [showModalBottomSheet] with Velora's chrome (rounded top corners at
/// `radiusLg`, the theme's surface color, an optional grab handle, and an
/// optional titled header) so callers get a consistent sheet without
/// re-styling it at every call site.
abstract final class VeloraBottomSheet {
  /// Shows a modal bottom sheet built from [builder] and returns its popped
  /// value.
  ///
  /// - [title], when given, renders a `titleMedium` header above the
  ///   content, separated by a hairline divider.
  /// - [showDragHandle] (default `true`) draws a small rounded grab handle
  ///   above the content.
  /// - [isScrollControlled] and [isDismissible] are forwarded to
  ///   [showModalBottomSheet] unchanged — set [isScrollControlled] to `true`
  ///   for a sheet whose content should be able to grow past half the
  ///   screen (e.g. one containing a text field with a keyboard).
  ///
  /// The content is padded by `spacingLg` and the sheet reserves bottom
  /// safe-area/keyboard inset space automatically.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    bool showDragHandle = true,
    bool isScrollControlled = false,
    bool isDismissible = true,
  }) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacingLg,
                tokens.spacingSm,
                tokens.spacingLg,
                tokens.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDragHandle)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spacingSm),
                      child: Center(
                        child: Container(
                          key: const Key('velora-bottom-sheet-drag-handle'),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusPill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (title != null) ...[
                    Text(title, style: textTheme.titleMedium),
                    SizedBox(height: tokens.spacingMd),
                    Divider(height: 1, color: scheme.outlineVariant),
                    SizedBox(height: tokens.spacingMd),
                  ],
                  Builder(builder: builder),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
