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
  /// offline, or the server is down) so ordering is preserved and the
  /// remaining items stay queued. A 4xx `ApiException` is treated as a
  /// poison pill: the request can never succeed as-is, so it is discarded
  /// rather than blocking the rest of the queue forever. Reentrancy-safe —
  /// a concurrent call (e.g. two rapid reconnect events) is a no-op. Never
  /// throws — a failed replay just leaves the queue as-is.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      while (pending.isNotEmpty) {
        final request = pending.first;
        try {
          await _replay(request);
        } catch (e) {
          if (e is ApiException &&
              e.statusCode != null &&
              e.statusCode! >= 400 &&
              e.statusCode! < 500) {
            // Permanent client error: discard and keep going.
            pending.removeAt(0);
            await _persist();
            continue;
          }
          // Still offline, server error, or unknown failure: halt and keep
          // the queue for the next reconnect.
          return;
        }
        pending.removeAt(0);
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
