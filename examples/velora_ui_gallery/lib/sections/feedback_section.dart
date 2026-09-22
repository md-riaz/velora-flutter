import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

/// Showcases velora_ui's Layer 6 feedback & overlay components:
/// [VeloraDialog], [VeloraBottomSheet], [VeloraToast], and [VeloraTooltip].
///
/// Every demo here is triggered by a tap that calls one of the imperative
/// `.show`/`.confirm` helpers using the tapped button's own [BuildContext],
/// so this section needs no local state of its own.
class FeedbackSection extends StatelessWidget {
  /// Creates the feedback & overlays showcase section.
  const FeedbackSection({super.key});

  Future<void> _showDialog(BuildContext context) {
    return VeloraDialog.show<void>(
      context,
      title: 'Welcome to Velora',
      message: 'This is a plain message dialog with a single close action.',
      actions: [
        VeloraButton(
          label: 'Close',
          variant: VeloraButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final confirmed = await VeloraDialog.confirm(
      context,
      title: 'Discard changes?',
      message: 'Your unsaved edits will be lost.',
    );
    if (!context.mounted) return;
    VeloraToast.show(
      context,
      message: confirmed == true ? 'Changes discarded' : 'Kept editing',
      status: confirmed == true ? VeloraStatus.warning : VeloraStatus.info,
    );
  }

  Future<void> _showDestructiveConfirmDialog(BuildContext context) async {
    final confirmed = await VeloraDialog.confirm(
      context,
      title: 'Delete item?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!context.mounted) return;
    VeloraToast.show(
      context,
      message: confirmed == true ? 'Item deleted' : 'Delete cancelled',
      status: confirmed == true ? VeloraStatus.error : VeloraStatus.info,
    );
  }

  Future<void> _showBottomSheet(BuildContext context) {
    return VeloraBottomSheet.show<void>(
      context,
      title: 'Sheet title',
      builder: (sheetContext) {
        final tokens = sheetContext.veloraTokens;
        final scheme = Theme.of(sheetContext).colorScheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A modal bottom sheet with a drag handle, a titled header, '
              'and arbitrary content below.',
              style: Theme.of(
                sheetContext,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: tokens.spacingLg),
            VeloraButton(
              label: 'Close',
              variant: VeloraButtonVariant.ghost,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VeloraSectionHeader(
          title: 'Dialogs',
          subtitle: 'Modal messages and confirm/cancel prompts',
        ),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            VeloraButton(
              label: 'Show dialog',
              onPressed: () => _showDialog(context),
            ),
            VeloraButton(
              label: 'Confirm',
              variant: VeloraButtonVariant.secondary,
              onPressed: () => _showConfirmDialog(context),
            ),
            VeloraButton(
              label: 'Delete (destructive)',
              variant: VeloraButtonVariant.danger,
              onPressed: () => _showDestructiveConfirmDialog(context),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Bottom sheet',
          subtitle: 'A modal sheet with a drag handle and titled header',
        ),
        VeloraButton(
          label: 'Show bottom sheet',
          variant: VeloraButtonVariant.outline,
          onPressed: () => _showBottomSheet(context),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Toasts',
          subtitle: 'Transient feedback via the scaffold messenger',
        ),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            VeloraButton(
              label: 'Show success',
              size: VeloraButtonSize.small,
              onPressed: () => VeloraToast.show(
                context,
                message: 'Saved successfully',
                status: VeloraStatus.success,
              ),
            ),
            VeloraButton(
              label: 'Show warning',
              size: VeloraButtonSize.small,
              onPressed: () => VeloraToast.show(
                context,
                message: 'Nearing your storage limit',
                status: VeloraStatus.warning,
              ),
            ),
            VeloraButton(
              label: 'Show info',
              size: VeloraButtonSize.small,
              onPressed: () => VeloraToast.show(
                context,
                message: 'A new version is available',
                status: VeloraStatus.info,
              ),
            ),
            VeloraButton(
              label: 'Show error',
              size: VeloraButtonSize.small,
              onPressed: () => VeloraToast.show(
                context,
                message: 'Something went wrong',
                status: VeloraStatus.error,
              ),
            ),
            VeloraButton(
              label: 'Show with action',
              size: VeloraButtonSize.small,
              variant: VeloraButtonVariant.outline,
              onPressed: () => VeloraToast.show(
                context,
                message: 'Message archived',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Tooltip',
          subtitle: 'Long-press (or hover, on desktop/web) the icon below',
        ),
        VeloraTooltip(
          message: 'More info',
          child: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: tokens.spacingSm),
        Text(
          'Long-press or hover the icon above to reveal its tooltip.',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
