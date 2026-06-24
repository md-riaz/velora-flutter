import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'velora_attachment.dart';

/// GetxService that wraps platform file and image pickers.
///
/// Available globally after [Velora.boot] via [Velora.media].
///
/// Usage:
/// ```dart
/// final photo  = await Velora.media.pickImage();
/// final shot   = await Velora.media.pickImage(source: ImageSource.camera);
/// final photos = await Velora.media.pickMultiImage();
/// final doc    = await Velora.media.pickFile(allowedExtensions: ['pdf','docx']);
/// final files  = await Velora.media.pickFiles();
/// ```
///
/// For the full integrated flow (bottom sheet picker + reactive attachment
/// list + upload progress) use [VeloraAttachmentsMixin] in your controller.
class VeloraMediaService extends GetxService {
  final _img = ImagePicker();

  /// Pick a single image from [source].
  ///
  /// Returns `null` if the user cancels or a platform error occurs.
  Future<VeloraAttachment?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final file = await _img.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (file == null) return null;
      return VeloraAttachment.local(
        path: file.path,
        name: file.name,
        mimeType: file.mimeType,
        sizeBytes: await file.length(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Pick multiple images from the gallery.
  Future<List<VeloraAttachment>> pickMultiImage({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final files = await _img.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return Future.wait(
        files.map(
          (f) async => VeloraAttachment.local(
            path: f.path,
            name: f.name,
            mimeType: f.mimeType,
            sizeBytes: await f.length(),
          ),
        ),
      );
    } catch (_) {
      return [];
    }
  }

  /// Pick a single arbitrary file.
  ///
  /// Pass [allowedExtensions] (without leading dot, e.g. `['pdf','docx']`)
  /// to restrict file types.
  Future<VeloraAttachment?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.first;
      if (f.path == null) return null;
      return VeloraAttachment.local(
        path: f.path!,
        name: f.name,
        sizeBytes: f.size,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pick multiple arbitrary files.
  Future<List<VeloraAttachment>> pickFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );
      if (result == null) return [];
      return result.files
          .where((f) => f.path != null)
          .map(
            (f) => VeloraAttachment.local(
              path: f.path!,
              name: f.name,
              sizeBytes: f.size,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
