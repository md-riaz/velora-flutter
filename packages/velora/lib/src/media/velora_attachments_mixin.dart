import 'package:flutter/widgets.dart' show Color;
import 'package:get/get.dart';

import '../ui/widgets/velora_attachment_picker_sheet.dart';
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
/// Wire the strip in your view — no `Obx` wrapper needed:
/// ```dart
/// VeloraAttachmentStrip(
///   attachments: controller.attachments,
///   onPickTap: controller.showAttachmentPicker,
///   onRemove: controller.removeAttachment,
///   onRetry: controller.retryAttachment,
/// )
/// ```
mixin VeloraAttachmentsMixin {
  final attachments = <VeloraAttachment>[].obs;
  final _uploadsInFlight = <String>{};

  /// Override in your controller to swap in the real upload adapter.
  VeloraUploadAdapter get uploadAdapter => const VeloraMockUploadAdapter();

  /// Opens the source picker and adds the selected files.
  ///
  /// If [config.uploadImmediately] is true, picked files are uploaded right
  /// after the picker closes.
  Future<void> showAttachmentPicker([
    VeloraPickerConfig config = const VeloraPickerConfig(),
  ]) async {
    final picked = await presentAttachmentPicker(config);
    if (picked == null || picked.isEmpty) return;
    for (final a in picked) {
      attachments.add(a);
    }
    if (config.uploadImmediately) await uploadAll();
  }

  /// Presents the picker UI and returns the chosen attachments (empty on
  /// cancel, `null` if dismissed). Override to supply your own picker UI
  /// without touching the pick/upload orchestration above.
  Future<List<VeloraAttachment>?> presentAttachmentPicker(
    VeloraPickerConfig config,
  ) {
    return Get.bottomSheet<List<VeloraAttachment>>(
      VeloraAttachmentPickerSheet(config: config),
      backgroundColor: const Color(0x00000000),
      isScrollControlled: true,
    );
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
    final idx = attachments.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    if (attachments[idx].status != AttachmentStatus.pending) return;
    if (!_uploadsInFlight.add(id)) return;

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
    } finally {
      _uploadsInFlight.remove(id);
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

  /// Upload all [AttachmentStatus.pending] attachments sequentially.
  ///
  /// Throws [StateError] if any attachment ends in [AttachmentStatus.error] so
  /// callers cannot silently submit with missing files.
  Future<void> uploadAll() async {
    for (final a in attachments
        .where((a) => a.status == AttachmentStatus.pending)
        .toList()) {
      await uploadAttachment(a.id);
    }
    final failed = attachments
        .where((a) => a.status == AttachmentStatus.error)
        .toList();
    if (failed.isNotEmpty) {
      throw StateError(
        '${failed.length} attachment(s) failed to upload. '
        'Remove or retry them before submitting.',
      );
    }
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
