import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;

import '../http/velora_api_service.dart';
import 'velora_attachment.dart';

/// The result returned by [VeloraUploadAdapter.upload].
///
/// Carries the display URL plus the server-assigned identifiers your backend
/// returns — numeric [mediaId] and [mediaUuid] from Laravel Media Library,
/// or just [url] for S3 / flat-file endpoints.
///
/// All fields from the raw server response are available in [meta] for
/// backends that return extra data (e.g. conversions, responsive images).
class VeloraUploadResult {
  final String url;
  final String? mediaId;
  final String? mediaUuid;
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
/// Replace with [LaravelMediaAdapter] (or your own adapter) before production:
/// ```dart
/// class MyController extends VeloraController with VeloraAttachmentsMixin {
///   @override
///   VeloraUploadAdapter get uploadAdapter => LaravelMediaAdapter();
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

/// Ready-to-use adapter for [Spatie Laravel Media Library](https://spatie.be/docs/laravel-medialibrary).
///
/// Uploads via multipart `POST` and maps the standard Laravel Media Library
/// JSON response — `id`, `uuid`, `original_url` — into [VeloraUploadResult].
///
/// The full response body is preserved in [VeloraUploadResult.meta] for
/// accessing custom properties, conversions, or responsive images.
///
/// ## Setup
///
/// 1. Register a route in `routes/api.php` (or reuse the default media endpoint):
/// ```php
/// Route::post('/media', [MediaController::class, 'store'])->middleware('auth:sanctum');
/// ```
///
/// 2. Wire the adapter in your controller:
/// ```dart
/// class PostController extends VeloraController with VeloraAttachmentsMixin {
///   @override
///   VeloraUploadAdapter get uploadAdapter => LaravelMediaAdapter();
///
///   Future<void> submit() async {
///     await uploadAll();
///     // Associate with the model on the server using the server-assigned IDs:
///     await Velora.api.post('/posts', data: {
///       'title': title.value,
///       'media_ids': mediaIds,   // e.g. ['42', '43']
///     });
///     attachments.clear();
///   }
/// }
/// ```
///
/// ## Custom Dio instance
///
/// By default the adapter uploads through [VeloraApiService.uploadFile] (already
/// authenticated via the Bearer token interceptor and error-normalized). Pass
/// your own [Dio] only if you need a separate HTTP client that bypasses the
/// service:
/// ```dart
/// LaravelMediaAdapter(dio: myCustomDio, endpoint: '/api/v2/media')
/// ```
class LaravelMediaAdapter implements VeloraUploadAdapter {
  final String endpoint;
  final Dio? _customDio;

  LaravelMediaAdapter({
    this.endpoint = '/api/media',
    Dio? dio,
  }) : _customDio = dio;

  @override
  Future<VeloraUploadResult> upload(
    VeloraAttachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    final localPath = attachment.localPath;
    if (localPath == null || localPath.isEmpty) {
      throw ArgumentError.value(
        attachment.id,
        'attachment',
        'Cannot upload an attachment without a local path (already remote?).',
      );
    }

    void reportProgress(int sent, int total) {
      if (total > 0) onProgress?.call(sent / total);
    }

    final Map<String, dynamic> body;
    final customDio = _customDio;
    if (customDio != null) {
      // Advanced escape hatch: a fully separate client, bypassing the service.
      final response = await customDio.post<Map<String, dynamic>>(
        endpoint,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            localPath,
            filename: attachment.name,
            contentType: attachment.mimeType != null
                ? DioMediaType.parse(attachment.mimeType!)
                : null,
          ),
        }),
        onSendProgress: reportProgress,
      );
      body = response.data ?? <String, dynamic>{};
    } else {
      body = await Get.find<VeloraApiService>().uploadFile(
        endpoint,
        filePath: localPath,
        filename: attachment.name,
        contentType: attachment.mimeType,
        onSendProgress: reportProgress,
      );
    }

    final url = _firstNonEmpty(body, const ['original_url', 'url', 'path']);
    if (url.isEmpty) {
      throw Exception(
        'LaravelMediaAdapter: upload response contained no usable URL. '
        'Expected one of: original_url, url, path. Response: $body',
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
