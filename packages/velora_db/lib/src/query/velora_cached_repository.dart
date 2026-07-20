import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:velora/velora.dart';

import 'socket_error.dart';
import 'velora_table.dart';

/// The default [VeloraCachedRepository.isOfflineError]: `true` for errors
/// that indicate the request never reached a server, `false` for everything
/// else (including a well-formed HTTP error response, e.g. 404/500).
///
/// Recognizes:
/// - [DioException] whose [DioExceptionType] is [DioExceptionType.connectionError],
///   [DioExceptionType.connectionTimeout], [DioExceptionType.receiveTimeout], or
///   [DioExceptionType.sendTimeout] — these are dio's "could not talk to the
///   server at all" states, as opposed to [DioExceptionType.badResponse]
///   (the server responded, just with an error status).
/// - [ApiException] with [ApiException.isConnectionError] set — this is the
///   *normalized* form of the same connection-level [DioException] states
///   above. `VeloraApiService._send` (the HTTP layer generated remote data
///   sources go through) catches every [DioException] and rethrows it as an
///   [ApiException] before it ever reaches this predicate, so without this
///   check a real connection failure in a generated repository would arrive
///   here as a plain [ApiException] — never matching the raw-[DioException]
///   branch above — and get incorrectly rethrown instead of falling back to
///   the cache.
/// - [SocketException] (dart:io, via a web-safe conditional import) — a
///   lower-level connection failure, in case the remote data source isn't
///   dio-based. Not available on Web, where it's always non-matching.
/// - [TimeoutException] (dart:async) — e.g. from `Future.timeout`.
bool defaultIsOfflineError(Object error) {
  if (error is DioException) {
    const offlineTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    return offlineTypes.contains(error.type);
  }
  if (error is ApiException) {
    return error.isConnectionError;
  }
  return isSocketException(error) || error is TimeoutException;
}

/// A network-first, read-through [VeloraRepository] that layers a local
/// [VeloraTable] cache in front of a [VeloraRemoteDataSource].
///
/// This is the offline-**read** counterpart to `velora_offline` (which
/// queues and replays offline **writes**); the two packages compose but
/// neither depends on the other — [VeloraCachedRepository] detects "offline"
/// purely via the pluggable [isOfflineError] predicate, never by importing
/// `velora_offline`.
///
/// Read behavior (network-first):
/// - [index] / [show] always try [remote] first. On success, the cache is
///   refreshed and the remote result is returned. If [remote] throws an
///   error that [isOfflineError] classifies as "offline", the cache is
///   served instead. Any other error (e.g. a 404/500 that *did* reach the
///   server) is rethrown as-is — it is not an offline condition and must
///   not be masked by a stale cache read.
///
/// Write behavior ([store] / [update] / [destroy]): always delegate to
/// [remote] as the source of truth; the cache is updated best-effort
/// afterwards so a cache write failure never masks or replaces the remote
/// result. This class does **not** support offline writes — queueing and
/// replaying writes made while offline is `velora_offline`'s job; layer that
/// package's remote data source underneath this one (or in front of it) if
/// you need both.
///
/// MVP caveat: [index] refreshes the cache by upserting every row from the
/// latest remote response; it does **not** evict rows that were cached
/// previously but are absent from the latest response (e.g. a since-deleted
/// remote row). A full "replace all cached rows with exactly this response"
/// eviction strategy is left for a future iteration.
class VeloraCachedRepository<T, ID> implements VeloraRepository<T, ID> {
  final VeloraRemoteDataSource<T, ID> remote;
  final VeloraTable<T, ID> cache;
  final Map<String, dynamic> Function(T model) toCacheMap;
  final bool Function(Object error) isOfflineError;

  VeloraCachedRepository({
    required this.remote,
    required this.cache,
    Map<String, dynamic> Function(T model)? toCacheMap,
    bool Function(Object error)? isOfflineError,
  }) : toCacheMap = toCacheMap ?? cache.toMap,
       isOfflineError = isOfflineError ?? defaultIsOfflineError;

  @override
  Future<List<T>> index() async {
    try {
      final items = await remote.index();
      await _tryCachePutAll(items);
      return items;
    } catch (error) {
      if (isOfflineError(error)) {
        return cache.all();
      }
      rethrow;
    }
  }

  @override
  Future<T> show(ID id) async {
    try {
      final item = await remote.show(id);
      await _tryCachePut(item);
      return item;
    } catch (error) {
      if (isOfflineError(error)) {
        final cached = await cache.find(id);
        if (cached != null) {
          return cached;
        }
        // Never cached (or evicted) -- nothing to serve, so surface the
        // original offline error rather than a synthetic "not found".
        rethrow;
      }
      rethrow;
    }
  }

  @override
  Future<T> store(Map<String, dynamic> data) async {
    final created = await remote.store(data);
    await _tryCachePut(created);
    return created;
  }

  @override
  Future<T> update(ID id, Map<String, dynamic> data) async {
    final updated = await remote.update(id, data);
    await _tryCachePut(updated);
    return updated;
  }

  @override
  Future<void> destroy(ID id) async {
    await remote.destroy(id);
    try {
      await cache.delete(id);
    } catch (_) {
      // Best-effort: the remote delete already succeeded and is the source
      // of truth; a stale cache row will simply be refreshed/evicted later.
    }
  }

  /// Best-effort upsert into the cache: a cache write failure never masks
  /// or replaces an already-successful remote result, in either the read
  /// paths ([index] / [show], refreshing the cache with fresh remote data)
  /// or the write paths ([store] / [update]).
  Future<void> _tryCachePut(T item) async {
    try {
      await cache.insert(toCacheMap(item));
    } catch (_) {
      // Swallowed intentionally -- see dartdoc above.
    }
  }

  /// Best-effort batch upsert into the cache: like [_tryCachePut], but
  /// refreshes many rows in a single SQLite transaction instead of one
  /// transaction per row. Used by [index], whose remote response can be
  /// large enough that per-row transactions would noticeably block the
  /// caller.
  Future<void> _tryCachePutAll(List<T> items) async {
    if (items.isEmpty) return;
    try {
      final batch = cache.db.batch();
      for (final item in items) {
        batch.insert(
          cache.table,
          toCacheMap(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Swallowed intentionally -- see dartdoc above.
    }
  }
}
