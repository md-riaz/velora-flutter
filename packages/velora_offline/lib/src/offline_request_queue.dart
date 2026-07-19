import 'package:velora/velora.dart';

import 'offline_request.dart';

/// Persists write requests made while offline and replays them, in order,
/// once connectivity is restored.
class OfflineRequestQueue {
  static const _storageKey = 'velora.offline.queue';

  final VeloraStorageService storage;
  final VeloraApiService api;

  final RxList<OfflineRequest> pending = <OfflineRequest>[].obs;

  bool _isFlushing = false;

  /// Whether [flush] is currently replaying the queue. While `true`, the
  /// [OfflineQueueInterceptor] skips enqueuing new failures, since those
  /// failures are replays whose errors would otherwise grow the queue
  /// without bound.
  bool get isFlushing => _isFlushing;

  OfflineRequestQueue({required this.storage, required this.api});

  /// Restores any previously persisted queue. Returns `this` for fluent
  /// chaining, mirroring `VeloraStorageService.init()`.
  Future<OfflineRequestQueue> load() async {
    final json = storage.getJson(_storageKey);
    final items = json?['items'];
    if (items is List) {
      pending.assignAll(
        items
            .whereType<Map>()
            .map((item) => OfflineRequest.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    }
    return this;
  }

  Future<void> enqueue(OfflineRequest request) async {
    pending.add(request);
    await _persist();
  }

  Future<void> clear() async {
    pending.clear();
    await _persist();
  }

  /// Replays queued requests in order via the matching `api.<method>` call.
  /// Stops at the first failure that isn't a permanent client error (still
  /// offline, the server is down, or a transient `408`/`429` response) so
  /// ordering is preserved and the remaining items stay queued. Any other
  /// 4xx `ApiException` is treated as a poison pill: the request can never
  /// succeed as-is, so it is discarded rather than blocking the rest of the
  /// queue forever. Reentrancy-safe — a concurrent call (e.g. two rapid
  /// reconnect events) is a no-op. Never throws — a failed replay just
  /// leaves the queue as-is.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      while (pending.isNotEmpty) {
        final request = pending.first;
        try {
          await _replay(request);
        } catch (e) {
          final statusCode = e is ApiException ? e.statusCode : null;
          if (statusCode != null &&
              statusCode >= 400 &&
              statusCode < 500 &&
              statusCode != 408 &&
              statusCode != 429) {
            // Permanent client error: discard and keep going. Removed by
            // identity (not index) so a concurrent clear() during the
            // await above can't cause a RangeError or drop the wrong item.
            pending.remove(request);
            await _persist();
            continue;
          }
          // Still offline, server error, or a transient client error
          // (408 Request Timeout / 429 Too Many Requests): halt and keep
          // the queue for the next reconnect.
          return;
        }
        pending.remove(request);
        await _persist();
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _replay(OfflineRequest request) {
    switch (request.method.toUpperCase()) {
      case 'POST':
        return api.post<Object?>(request.path, data: request.data);
      case 'PUT':
        return api.put<Object?>(request.path, data: request.data);
      case 'PATCH':
        return api.patch<Object?>(request.path, data: request.data);
      case 'DELETE':
        return api.delete<Object?>(request.path, data: request.data);
      default:
        return api.post<Object?>(request.path, data: request.data);
    }
  }

  Future<void> _persist() {
    return storage.setJson(_storageKey, {
      'items': pending.map((request) => request.toJson()).toList(),
    });
  }
}
