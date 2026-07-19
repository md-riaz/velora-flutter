import 'dart:async';

import 'package:dio/dio.dart';
import 'package:velora/velora.dart';

import 'offline_request.dart';
import 'offline_request_queue.dart';

const _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

/// Queues write requests (POST/PUT/PATCH/DELETE) that fail with a
/// connection-level error (no server response reached), so they can be
/// replayed once connectivity is restored.
///
/// The original error is still passed through via `handler.next(err)` — the
/// caller sees the failure immediately (e.g. to show "saved offline" UI);
/// the write itself is queued in the background for [OfflineRequestQueue]
/// to replay.
class OfflineQueueInterceptor extends VeloraApiInterceptor {
  final OfflineRequestQueue queue;

  OfflineQueueInterceptor(this.queue);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isConnectionFailure = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout;
    final method = err.requestOptions.method.toUpperCase();

    if (isConnectionFailure && _writeMethods.contains(method)) {
      final rawData = err.requestOptions.data;
      final isSerializable = rawData == null ||
          rawData is Map ||
          rawData is List ||
          rawData is String ||
          rawData is num ||
          rawData is bool;
      final request = OfflineRequest(
        id: '${DateTime.now().microsecondsSinceEpoch}-${err.requestOptions.path}',
        method: method,
        path: err.requestOptions.path,
        data: isSerializable ? rawData : null,
        createdAt: DateTime.now(),
      );
      // Fire-and-forget: persisting the queue must not delay error
      // propagation to the caller.
      unawaited(queue.enqueue(request));
    }

    handler.next(err);
  }
}
