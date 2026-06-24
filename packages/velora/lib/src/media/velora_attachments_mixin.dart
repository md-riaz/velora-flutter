import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'velora_attachment.dart';
import 'velora_upload_adapter.dart';

/// Mix into any [GetxController] subclass to add reactive attachment
/// management: picking, uploading with progress, retry, and removal.
///
/// ```dart
/// class PostController extends VeloraController with VeloraAttachmentsMixin {
///   // Override to use your real upload endpoint in production.
///   @override
///   VeloraUploadAdapter get uploadAdapter => LaravelMediaAdapter();
///
///   Future<void> submit() async {
///     await uploadAll();                              // upload pending files
///     await _api.createPost(text: body.value, data: {
///       'media_ids': mediaIds,                       // server-assigned IDs
///     });
///     attachments.clear();
///   }
/// }
/// ```
///
/// Wire the strip in your view:
/// ```dart
/// Obx(() => VeloraAttachmentStrip(
///   attachments: controller.attachments,
///   onPickTap: controller.showAttachmentPicker,
///   onRemove: controller.removeAttachment,
///   onRetry: controller.retryAttachment,
/// ))
/// ```
mixin VeloraAttachmentsMixin {
  final attachments = <VeloraAttachment>[].obs;

  /// Override in your controller to swap in the real upload adapter.
  VeloraUploadAdapter get uploadAdapter => const VeloraMockUploadAdapter();

  /// Opens the source picker bottom sheet and adds the selected files.
  ///
  /// If [config.uploadImmediately] is true, picked files are uploaded right
  /// after the picker closes.
  Future<void> showAttachmentPicker([
    VeloraPickerConfig config = const VeloraPickerConfig(),
  ]) async {
    final picked = await Get.bottomSheet<List<VeloraAttachment>>(
      _AttachmentPickerSheet(config: config),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (picked == null || picked.isEmpty) return;
    for (final a in picked) {
      attachments.add(a);
    }
    if (config.uploadImmediately) await uploadAll();
  }

  /// Append a pre-built attachment (e.g. loaded from remote).
  void addAttachment(VeloraAttachment attachment) {
    attachments.add(attachment);
  }

  /// Remove an attachment by [id], regardless of its upload status.
  void removeAttachment(String id) {
    attachments.removeWhere((a) => a.id == id);
  }

  /// Upload a single [AttachmentStatus.pending] attachment.
  ///
  /// Transitions through [AttachmentStatus.uploading] → [AttachmentStatus.done]
  /// (or [AttachmentStatus.error] on failure).  Safe to call concurrently.
  Future<void> uploadAttachment(String id) async {
    var idx = attachments.indexWhere((a) => a.id == id);
    if (idx < 0) return;

    attachments[idx] = attachments[idx].copyWith(
      status: AttachmentStatus.uploading,
      progress: 0,
    );

    try {
      final result = await uploadAdapter.upload(
        attachments[idx],
        onProgress: (p) {
          final i = attachments.indexWhere((a) => a.id == id);
          if (i >= 0) attachments[i] = attachments[i].copyWith(progress: p);
        },
      );
      final i = attachments.indexWhere((a) => a.id == id);
      if (i >= 0) {
        attachments[i] = attachments[i].copyWith(
          status: AttachmentStatus.done,
          remoteUrl: result.url,
          mediaId: result.mediaId,
          mediaUuid: result.mediaUuid,
          progress: 1,
        );
      }
    } catch (e) {
      final i = attachments.indexWhere((a) => a.id == id);
      if (i >= 0) {
        attachments[i] = attachments[i].copyWith(
          status: AttachmentStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Reset an errored attachment to [AttachmentStatus.pending] and retry.
  Future<void> retryAttachment(String id) async {
    final idx = attachments.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      attachments[idx] = attachments[idx].copyWith(
        status: AttachmentStatus.pending,
        progress: 0,
      );
      await uploadAttachment(id);
    }
  }

  /// Upload all [AttachmentStatus.pending] attachments concurrently.
  Future<void> uploadAll() async {
    final pending = attachments
        .where((a) => a.status == AttachmentStatus.pending)
        .toList();
    await Future.wait(pending.map((a) => uploadAttachment(a.id)));
  }

  bool get hasAttachments => attachments.isNotEmpty;

  bool get isUploading =>
      attachments.any((a) => a.status == AttachmentStatus.uploading);

  bool get allSettled => attachments.every(
        (a) =>
            a.status == AttachmentStatus.done ||
            a.status == AttachmentStatus.error,
      );

  /// Remote URLs for all successfully uploaded attachments.
  List<String> get uploadedUrls => attachments
      .where((a) => a.remoteUrl != null)
      .map((a) => a.remoteUrl!)
      .toList();

  /// Server-assigned media IDs for all successfully uploaded attachments.
  ///
  /// Use this with Laravel Media Library to associate uploaded files with a
  /// model: `await api.post('/posts', data: {'media_ids': mediaIds})`.
  List<String> get mediaIds => attachments
      .where((a) => a.mediaId != null)
      .map((a) => a.mediaId!)
      .toList();

  /// Server-assigned UUIDs for all successfully uploaded attachments.
  List<String> get mediaUuids => attachments
      .where((a) => a.mediaUuid != null)
      .map((a) => a.mediaUuid!)
      .toList();
}

// ---------------------------------------------------------------------------
// Private picker bottom sheet
// ---------------------------------------------------------------------------

class _AttachmentPickerSheet extends StatelessWidget {
  final VeloraPickerConfig config;
  const _AttachmentPickerSheet({required this.config});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Add attachment',
                style:
                    textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            if (config.allowCamera)
              _PickerTile(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => _fromCamera(),
              ),
            if (config.allowGallery)
              _PickerTile(
                icon: Icons.photo_library_outlined,
                label:
                    config.allowMultiple ? 'Photo Library' : 'Choose Photo',
                onTap: () => _fromGallery(),
              ),
            if (config.allowFiles)
              _PickerTile(
                icon: Icons.attach_file_rounded,
                label: 'Files',
                onTap: () => _fromFiles(),
              ),
            Divider(height: 1, color: scheme.outlineVariant),
            _PickerTile(
              icon: Icons.close,
              label: 'Cancel',
              onTap: () =>
                  Get.back<List<VeloraAttachment>>(result: const []),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _fromCamera() async {
    final a = await Get.find<VeloraMediaService>().pickImage(
      source: ImageSource.camera,
      imageQuality: config.imageQuality,
    );
    Get.back<List<VeloraAttachment>>(result: a != null ? [a] : const []);
  }

  Future<void> _fromGallery() async {
    final media = Get.find<VeloraMediaService>();
    if (config.allowMultiple) {
      final list =
          await media.pickMultiImage(imageQuality: config.imageQuality);
      Get.back<List<VeloraAttachment>>(result: list);
    } else {
      final a = await media.pickImage(
        source: ImageSource.gallery,
        imageQuality: config.imageQuality,
      );
      Get.back<List<VeloraAttachment>>(result: a != null ? [a] : const []);
    }
  }

  Future<void> _fromFiles() async {
    final media = Get.find<VeloraMediaService>();
    if (config.allowMultiple) {
      final list = await media.pickFiles(
        allowedExtensions: config.allowedFileExtensions,
      );
      Get.back<List<VeloraAttachment>>(result: list);
    } else {
      final a = await media.pickFile(
        allowedExtensions: config.allowedFileExtensions,
      );
      Get.back<List<VeloraAttachment>>(result: a != null ? [a] : const []);
    }
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
