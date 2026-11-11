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
  /// When `true`, platform errors (permission denied, channel failure) are
  /// rethrown so callers can react, while a user cancel still returns `null`/`[]`
  /// (the pickers return null on cancel rather than throwing). Off by default to
  /// preserve the fire-and-forget picking flow.
  final bool rethrowErrors;

  VeloraMediaService({this.rethrowErrors = false});

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
      if (rethrowErrors) rethrow;
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
      return await Future.wait(
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
      if (rethrowErrors) rethrow;
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
      final f = await FilePicker.pickFile(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
      );
      final path = f?.path;
      if (f == null || path == null) return null;
      return VeloraAttachment.local(
        path: path,
        name: f.name,
        sizeBytes: await f.length(),
      );
    } catch (_) {
      if (rethrowErrors) rethrow;
      return null;
    }
  }

  /// Pick multiple arbitrary files.
  Future<List<VeloraAttachment>> pickFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: allowedExtensions != null ? FileType.custom : type,
        allowedExtensions: allowedExtensions,
      );
      return await Future.wait(
        files.where((f) => f.path != null).map(
              (f) async => VeloraAttachment.local(
                path: f.path!,
                name: f.name,
                sizeBytes: await f.length(),
              ),
            ),
      );
    } catch (_) {
      if (rethrowErrors) rethrow;
      return [];
    }
  }
}
