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

  /// Request paths that must never be queued (e.g. auth login/logout/me
  /// endpoints) — replaying them later could resend plaintext credentials or
  /// revoke the wrong session under a different bearer token.
  final Set<String> excludedPaths;

  /// Optional user-supplied predicate for additional exclusion logic. Return
  /// `false` to skip queuing a given request; `null` (the default) queues
  /// everything not otherwise excluded.
  final bool Function(RequestOptions options)? shouldQueue;

  OfflineQueueInterceptor(
    this.queue, {
    this.excludedPaths = const {},
    this.shouldQueue,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isConnectionFailure = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout;
    final method = err.requestOptions.method.toUpperCase();

    if (isConnectionFailure && _writeMethods.contains(method)) {
      // Replays happen while the queue is flushing; a replay that fails again
      // must not be re-enqueued, or the queue would grow without bound.
      final isReplay = queue.isFlushing;
      final isExcluded = excludedPaths.contains(err.requestOptions.path) ||
          (shouldQueue != null && !shouldQueue!(err.requestOptions));

      if (!isReplay && !isExcluded) {
        final rawData = err.requestOptions.data;
        final isSerializable = rawData == null ||
            rawData is Map ||
            rawData is List ||
            rawData is String ||
            rawData is num ||
            rawData is bool;

        if (isSerializable) {
          final request = OfflineRequest(
            id: '${DateTime.now().microsecondsSinceEpoch}-${err.requestOptions.path}',
            method: method,
            path: err.requestOptions.path,
            data: rawData,
            createdAt: DateTime.now(),
          );
          // Fire-and-forget: persisting the queue must not delay error
          // propagation to the caller.
          unawaited(queue.enqueue(request));
        }
      }
    }

    handler.next(err);
  }
}
