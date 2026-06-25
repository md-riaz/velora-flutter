import 'package:flutter/material.dart';

import '../../media/velora_attachment.dart';
import 'velora_attachment_chip.dart';

/// Horizontally scrollable strip of [VeloraAttachmentChip]s.
///
/// Place above the input bar in chat or form screens.  Wire callbacks to
/// your controller's [VeloraAttachmentsMixin] methods.
///
/// The strip hides itself when [attachments] is empty.
///
/// ```dart
/// Obx(() => VeloraAttachmentStrip(
///   attachments: controller.attachments,
///   onPickTap: controller.showAttachmentPicker,
///   onRemove: controller.removeAttachment,
///   onRetry: controller.retryAttachment,
/// ))
/// ```
class VeloraAttachmentStrip extends StatelessWidget {
  final List<VeloraAttachment> attachments;

  /// Called when the user taps the "add more" button at the end of the strip.
  final VoidCallback? onPickTap;

  final void Function(String id)? onRemove;
  final void Function(String id)? onRetry;

  const VeloraAttachmentStrip({
    required this.attachments,
    this.onPickTap,
    this.onRemove,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 136,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length + (onPickTap != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == attachments.length) {
            return _AddMoreButton(onTap: onPickTap!, scheme: scheme);
          }
          final a = attachments[index];
          return VeloraAttachmentChip(
            attachment: a,
            onRemove: onRemove != null ? () => onRemove!(a.id) : null,
            onRetry: onRetry != null ? () => onRetry!(a.id) : null,
          );
        },
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _AddMoreButton({required this.onTap, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Tooltip(
        message: 'Add attachment',
        child: IconButton.outlined(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(48, double.infinity),
          ),
          icon: Icon(Icons.add, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
