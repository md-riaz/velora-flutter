import 'package:flutter/material.dart';

import '../../media/velora_attachment.dart';
import '_file_image_stub.dart' if (dart.library.io) '_file_image_io.dart';

/// A thumbnail-style chip for a single [VeloraAttachment].
///
/// Shows an image preview or a file-type icon, the filename, file size,
/// an animated upload progress bar, and per-attachment remove/retry actions.
///
/// Designed for use inside [VeloraAttachmentStrip].
class VeloraAttachmentChip extends StatelessWidget {
  final VeloraAttachment attachment;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  const VeloraAttachmentChip({
    required this.attachment,
    this.onRemove,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isError = attachment.status == AttachmentStatus.error;

    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? scheme.error : scheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: _Thumbnail(attachment: attachment),
              ),
              // Remove button — uses IconButton for keyboard focus and a11y semantics
              if (onRemove != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onRemove,
                      iconSize: 14,
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove',
                      icon: Icon(Icons.close, size: 14, color: scheme.onSurface),
                    ),
                  ),
                ),
              // Upload progress bar
              if (attachment.status == AttachmentStatus.uploading)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: attachment.progress,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: isError
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (isError && onRetry != null)
                      IconButton(
                        onPressed: onRetry,
                        iconSize: 13,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Retry upload',
                        icon: Icon(Icons.refresh, size: 13, color: scheme.error),
                      )
                    else if (attachment.status == AttachmentStatus.done)
                      Icon(Icons.check_circle_outline,
                          size: 12, color: scheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    switch (attachment.status) {
      case AttachmentStatus.pending:
        return attachment.displaySize.isEmpty ? 'Ready' : attachment.displaySize;
      case AttachmentStatus.uploading:
        return '${(attachment.progress * 100).toInt()}%';
      case AttachmentStatus.done:
        return attachment.displaySize.isEmpty ? 'Uploaded' : attachment.displaySize;
      case AttachmentStatus.error:
        return 'Failed — use ↺ to retry';
    }
  }
}

// ---------------------------------------------------------------------------
// Private thumbnail widget
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final VeloraAttachment attachment;
  const _Thumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (attachment.isImage && attachment.localPath != null) {
      return buildFileImagePreview(attachment, scheme);
    }

    if (attachment.isImage && attachment.remoteUrl != null) {
      return Image.network(
        attachment.remoteUrl!,
        width: 112,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _FilePlaceholder(icon: Icons.broken_image_outlined, scheme: scheme),
      );
    }

    return _FilePlaceholder(
      icon: _iconForMime(attachment),
      scheme: scheme,
    );
  }

  static IconData _iconForMime(VeloraAttachment a) {
    if (a.isPdf) return Icons.picture_as_pdf_outlined;
    if (a.isVideo) return Icons.videocam_outlined;
    if (a.isAudio) return Icons.audiotrack_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

class _FilePlaceholder extends StatelessWidget {
  final IconData icon;
  final ColorScheme scheme;
  const _FilePlaceholder({required this.icon, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 72,
      child: Center(
        child: Icon(icon, size: 30, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
