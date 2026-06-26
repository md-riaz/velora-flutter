import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../media/velora_attachment.dart';
import 'velora_attachment_chip.dart';

const _kStripHeight = 136.0;

/// Horizontally scrollable strip of [VeloraAttachmentChip]s.
///
/// Place above the input bar in chat or form screens.  Wire callbacks to
/// your controller's [VeloraAttachmentsMixin] methods.
///
/// The strip subscribes to [attachments] reactively and hides itself when
/// the list is empty — no [Obx] wrapper needed at the call site:
///
/// ```dart
/// VeloraAttachmentStrip(
///   attachments: controller.attachments,
///   onPickTap: controller.showAttachmentPicker,
///   onRemove: controller.removeAttachment,
///   onRetry: controller.retryAttachment,
/// )
/// ```
class VeloraAttachmentStrip extends StatelessWidget {
  final RxList<VeloraAttachment> attachments;

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
    return Obx(() {
      if (attachments.isEmpty) return const SizedBox.shrink();

      final items = attachments.value;
      final scheme = Theme.of(context).colorScheme;

      return Container(
        height: _kStripHeight,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length + (onPickTap != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return _AddMoreButton(onTap: onPickTap!, scheme: scheme);
            }
            final a = items[index];
            return VeloraAttachmentChip(
              attachment: a,
              onRemove: onRemove != null ? () => onRemove!(a.id) : null,
              onRetry: onRetry != null ? () => onRetry!(a.id) : null,
            );
          },
        ),
      );
    });
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
