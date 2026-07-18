import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../media/velora_attachment.dart';
import '../../media/velora_media_service.dart';

/// Bottom-sheet UI that lets the user pick attachments from the camera,
/// gallery, or file system.
///
/// This is presentation only — it returns the picked attachments via
/// [Get.back] and holds no upload/business logic. It is opened by
/// `VeloraAttachmentsMixin.showAttachmentPicker`, but you can present it
/// yourself or subclass/replace it to fully restyle the picker:
///
/// ```dart
/// final picked = await Get.bottomSheet<List<VeloraAttachment>>(
///   const VeloraAttachmentPickerSheet(),
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
/// );
/// ```
class VeloraAttachmentPickerSheet extends StatelessWidget {
  final VeloraPickerConfig config;

  /// Sheet title. Override for localization or different wording.
  final String title;

  /// Camera row label.
  final String cameraLabel;

  /// Gallery row label when picking multiple images.
  final String galleryLabel;

  /// Gallery row label when picking a single image.
  final String choosePhotoLabel;

  /// Files row label.
  final String filesLabel;

  /// Cancel row label.
  final String cancelLabel;

  const VeloraAttachmentPickerSheet({
    this.config = const VeloraPickerConfig(),
    this.title = 'Add attachment',
    this.cameraLabel = 'Camera',
    this.galleryLabel = 'Photo Library',
    this.choosePhotoLabel = 'Choose Photo',
    this.filesLabel = 'Files',
    this.cancelLabel = 'Cancel',
    super.key,
  });

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
                title,
                style:
                    textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            if (config.allowCamera)
              _PickerTile(
                icon: Icons.camera_alt_outlined,
                label: cameraLabel,
                onTap: _fromCamera,
              ),
            if (config.allowGallery)
              _PickerTile(
                icon: Icons.photo_library_outlined,
                label: config.allowMultiple ? galleryLabel : choosePhotoLabel,
                onTap: _fromGallery,
              ),
            if (config.allowFiles)
              _PickerTile(
                icon: Icons.attach_file_rounded,
                label: filesLabel,
                onTap: _fromFiles,
              ),
            Divider(height: 1, color: scheme.outlineVariant),
            _PickerTile(
              icon: Icons.close,
              label: cancelLabel,
              onTap: () => Get.back<List<VeloraAttachment>>(result: const []),
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
      final list = await media.pickMultiImage(imageQuality: config.imageQuality);
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
