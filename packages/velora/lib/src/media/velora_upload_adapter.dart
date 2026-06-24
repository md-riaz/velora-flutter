import 'velora_attachment.dart';

/// Implement this interface to wire your server's file upload endpoint.
///
/// Return the remote URL of the uploaded file on success; throw [Exception]
/// on failure so [VeloraAttachmentsMixin] can set the error state.
///
/// ## Real implementation example
/// ```dart
/// class MyUploadAdapter implements VeloraUploadAdapter {
///   @override
///   Future<String> upload(
///     VeloraAttachment attachment, {
///     void Function(double progress)? onProgress,
///   }) async {
///     final formData = FormData.fromMap({
///       'file': await MultipartFile.fromFile(
///         attachment.localPath!,
///         filename: attachment.name,
///       ),
///     });
///     final res = await Velora.api.post(
///       '/uploads',
///       data: formData,
///       onSendProgress: (sent, total) => onProgress?.call(sent / total),
///     );
///     return res['url'] as String;
///   }
/// }
/// ```
abstract class VeloraUploadAdapter {
  Future<String> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  });
}

/// Development stub — simulates upload latency and progress callbacks.
///
/// Replace with your real [VeloraUploadAdapter] before production:
/// ```dart
/// class MyController extends VeloraController with VeloraAttachmentsMixin {
///   @override
///   VeloraUploadAdapter get uploadAdapter => MyUploadAdapter();
/// }
/// ```
class VeloraMockUploadAdapter implements VeloraUploadAdapter {
  final int totalDelayMs;

  const VeloraMockUploadAdapter({this.totalDelayMs = 1500});

  @override
  Future<String> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    const steps = 10;
    final stepDelay = Duration(milliseconds: totalDelayMs ~/ steps);
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDelay);
      onProgress?.call(i / steps);
    }
    return 'https://mock.velora.dev/uploads/${attachment.id}/${attachment.name}';
  }
}
