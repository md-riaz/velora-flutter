import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;

import '../http/velora_api_service.dart';
import 'velora_attachment.dart';

/// The result returned by [VeloraUploadAdapter.upload].
///
/// Carries the display URL plus any server-assigned identifiers your backend
/// returns. The full raw response is in [meta] for backends that return extra
/// fields (e.g. image dimensions, conversions, CDN keys).
class VeloraUploadResult {
  final String url;

  /// Server-assigned numeric or string ID, if returned by the backend.
  final String? mediaId;

  /// Server-assigned UUID, if returned by the backend.
  final String? mediaUuid;

  /// Full raw response body — access any extra fields your backend returns.
  final Map<String, dynamic> meta;

  const VeloraUploadResult({
    required this.url,
    this.mediaId,
    this.mediaUuid,
    this.meta = const {},
  });
}

/// Implement this interface to wire your server's file upload endpoint.
///
/// Return [VeloraUploadResult] on success; throw [Exception] on failure so
/// [VeloraAttachmentsMixin] can transition the attachment to the error state.
abstract class VeloraUploadAdapter {
  Future<VeloraUploadResult> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  });
}

/// Development stub — simulates upload latency and progress callbacks.
///
/// Returns a mock URL plus a fake [VeloraUploadResult.mediaId] so you can
/// exercise the full pick → upload → submit flow without a real backend.
///
/// Replace with [MultipartUploadAdapter] (or your own adapter) before production:
/// ```dart
/// class MyController extends VeloraController with VeloraAttachmentsMixin {
///   @override
///   VeloraUploadAdapter get uploadAdapter => MultipartUploadAdapter();
/// }
/// ```
class VeloraMockUploadAdapter implements VeloraUploadAdapter {
  final int totalDelayMs;

  const VeloraMockUploadAdapter({this.totalDelayMs = 1500});

  @override
  Future<VeloraUploadResult> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    const steps = 10;
    final stepDelay = Duration(milliseconds: totalDelayMs ~/ steps);
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDelay);
      onProgress?.call(i / steps);
    }
    return VeloraUploadResult(
      url: 'https://mock.velora.dev/uploads/${attachment.id}/${attachment.name}',
      mediaId: _fakeId(),
      mediaUuid: attachment.id,
    );
  }

  static int _counter = 1000;
  static String _fakeId() => (++_counter).toString();
}

/// General-purpose multipart file upload adapter.
///
/// Uploads via `multipart/form-data POST` and maps the server's JSON response
/// into [VeloraUploadResult]. Works with any backend that accepts a file upload
/// and returns a URL in the response body.
///
/// The adapter checks `original_url`, `url`, and `path` (in that order) for
/// the file URL — cover the most common response shapes out of the box.
/// The full response is also available in [VeloraUploadResult.meta].
///
/// ## Wiring it up
///
/// ```dart
/// class PostController extends VeloraController with VeloraAttachmentsMixin {
///   @override
///   VeloraUploadAdapter get uploadAdapter => MultipartUploadAdapter(
///     endpoint: '/api/uploads',
///     urlKey: 'file_url',   // override if your backend uses a different key
///   );
///
///   Future<void> submit() async {
///     await uploadAll();
///     await Velora.api.post('/posts', data: {
///       'title': title.value,
///       'attachment_ids': mediaIds,
///     });
///     attachments.clear();
///   }
/// }
/// ```
///
/// ## Custom Dio instance
///
/// By default the adapter uses `Velora.api.dio` (already authenticated via the
/// Bearer token interceptor). Pass your own [Dio] only if you need a separate
/// HTTP client:
/// ```dart
/// MultipartUploadAdapter(dio: myCustomDio, endpoint: '/v2/files')
/// ```
class MultipartUploadAdapter implements VeloraUploadAdapter {
  final String endpoint;

  /// JSON keys to check for the uploaded file URL, tried in order.
  final List<String> urlKeys;

  final Dio? _customDio;

  MultipartUploadAdapter({
    this.endpoint = '/api/media',
    this.urlKeys = const ['original_url', 'url', 'path'],
    Dio? dio,
  }) : _customDio = dio;

  Dio get _dio => _customDio ?? Get.find<VeloraApiService>().dio;

  @override
  Future<VeloraUploadResult> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        attachment.localPath!,
        filename: attachment.name,
        contentType: attachment.mimeType != null
            ? DioMediaType.parse(attachment.mimeType!)
            : null,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    final body = response.data ?? <String, dynamic>{};
    final url = _firstNonEmpty(body, urlKeys);
    if (url.isEmpty) {
      throw Exception(
        'MultipartUploadAdapter: upload response contained no usable URL. '
        'Checked keys: $urlKeys. Response: $body',
      );
    }
    return VeloraUploadResult(
      url: url,
      mediaId: body['id']?.toString(),
      mediaUuid: body['uuid'] as String?,
      meta: Map<String, dynamic>.from(body),
    );
  }

  static String _firstNonEmpty(Map<String, dynamic> body, List<String> keys) {
    for (final k in keys) {
      final v = body[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }
}

/// Backwards-compatible alias for [MultipartUploadAdapter].
typedef LaravelMediaAdapter = MultipartUploadAdapter;
