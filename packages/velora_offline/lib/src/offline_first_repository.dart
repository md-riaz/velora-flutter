import 'dart:async';

import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

import 'connectivity_service.dart';
import 'offline_request.dart';
import 'offline_request_queue.dart';

/// A local-first, reactive [VeloraRepository] over a [VeloraTable]: reads
/// come straight from the local reactive store and writes are optimistic
/// (applied locally first, for an instantly-updating UI) plus queued for
/// eventual server sync via [queue].
///
/// This is the Dexie-in-a-browser model applied to Velora:
///
/// 1. **Reads are reactive and local-first.** [table] — the local drift-
///    backed store from `velora_db` — is the source of truth for every read.
///    [watchAll] / [watchQuery] / [watchFind] return Streams that emit
///    immediately and re-emit on every local write, so UI bound to them
///    updates instantly and works fully offline. [index] / [show] are
///    one-shot equivalents that also satisfy [VeloraRepository].
/// 2. **Writes are optimistic-local plus outbox sync.** [store] / [update] /
///    [destroy] write to [table] *first* (so watchers fire immediately),
///    then enqueue a matching request onto [queue] for eventual delivery to
///    the server over conventional Laravel resource routes rooted at
///    [endpoint]: create → `POST {endpoint}`, update → `PUT {endpoint}/{id}`,
///    delete → `DELETE {endpoint}/{id}`. If [connectivity] is already online,
///    a flush is kicked off immediately; otherwise the enqueued request just
///    waits for `VeloraOfflinePlugin`'s `connectivity.onOnline` hook to flush
///    it on reconnect. If the outbox enqueue fails to persist, the optimistic
///    local mutation is rolled back (and the error rethrown) so [table] never
///    diverges from the durable outbox.
/// 3. **IDs must be client-generated for offline creates.** Because [store]
///    writes to [table] before the server has ever seen the row, there is no
///    server-assigned id to fall back on while offline — include the primary
///    key in the `data` map passed to [store] yourself (e.g. a UUID
///    generated on-device), rather than relying on a database default or a
///    server response to supply it. [store] enforces this: it throws an
///    [ArgumentError] if the primary key is absent from `data`.
/// 4. **Server→local reconciliation is the app's job.** This class only
///    pushes local writes outward; it never pulls fresh data down. Wiring a
///    poll or a websocket that writes server data back into [table] (via
///    `table.create`/`table.update`, an upsert, etc.) is up to the app —
///    once it does, the write reactively flows through to every open
///    [watchAll] / [watchQuery] / [watchFind] stream, same as a local write
///    would.
///
/// Contrast with `VeloraCachedRepository` (in `velora_db`): that repository
/// is **network-first**, read-through caching — reads always try the remote
/// API first and only fall back to the local cache when offline, and writes
/// go straight to the remote API with the cache updated best-effort
/// afterwards. [VeloraOfflineFirstRepository] inverts that: reads never touch
/// the network at all, and writes land locally before the network is even
/// attempted. Pick [VeloraCachedRepository] when the server should always win
/// when reachable; pick this class when the local store should always be
/// what the UI renders, network or not.
class VeloraOfflineFirstRepository<T, ID> implements VeloraRepository<T, ID> {
  final VeloraTable<T, ID> table;
  final OfflineRequestQueue queue;
  final ConnectivityService connectivity;
  final String endpoint;

  VeloraOfflineFirstRepository({
    required this.table,
    required this.queue,
    required this.connectivity,
    required this.endpoint,
  });

  /// A reactive version of [index]: emits the current rows immediately, then
  /// re-emits every time [table] changes -- the primary way UI should
  /// consume this repository.
  Stream<List<T>> watchAll() => table.watchAll();

  /// A reactive version of running [query] via [table]: emits the current
  /// matching rows immediately, then re-emits every time [table] changes.
  Stream<List<T>> watchQuery(QueryBuilder query) => table.watchQuery(query);

  /// A reactive version of [show]: emits the current row (or `null`)
  /// immediately, then re-emits every time [table] changes.
  Stream<T?> watchFind(ID id) => table.watchFind(id);

  /// A fresh, unfiltered [QueryBuilder] over [table], for building a filter
  /// to pass to [watchQuery].
  QueryBuilder query() => table.query();

  @override
  Future<List<T>> index() => table.all();

  @override
  Future<T> show(ID id) async {
    final model = await table.find(id);
    if (model == null) {
      throw StateError('No row found in "${table.table}" for id $id.');
    }
    return model;
  }

  @override
  Future<T> store(Map<String, dynamic> data) async {
    _requireClientGeneratedId(data);
    // Local write first -- this is what makes watchAll()/watchQuery()/
    // watchFind() re-emit immediately, before the server ever hears about it.
    final model = await table.create(data);
    try {
      await _enqueueSync('POST', endpoint, data);
    } catch (_) {
      // Enqueue failed to persist the outbox request: undo the optimistic
      // local write so the table never diverges from a durable sync request.
      await table.delete(data[table.primaryKey] as ID);
      rethrow;
    }
    return model;
  }

  @override
  Future<T> update(ID id, Map<String, dynamic> data) async {
    final prior = await table.find(id);
    await table.update(id, data);
    try {
      await _enqueueSync('PUT', '$endpoint/$id', data);
    } catch (_) {
      // Restore the prior row so the local table stays consistent with the
      // durable outbox. (If there was no prior row, the update affected
      // nothing and there is nothing to restore.)
      if (prior != null) {
        await table.insert(table.toMap(prior));
      }
      rethrow;
    }
    return show(id);
  }

  @override
  Future<void> destroy(ID id) async {
    final prior = await table.find(id);
    await table.delete(id);
    try {
      await _enqueueSync('DELETE', '$endpoint/$id', null);
    } catch (_) {
      // Re-insert the row we just deleted so the local table stays consistent
      // with the durable outbox.
      if (prior != null) {
        await table.insert(table.toMap(prior));
      }
      rethrow;
    }
  }

  void _requireClientGeneratedId(Map<String, dynamic> data) {
    if (data[table.primaryKey] == null) {
      throw ArgumentError.value(
        data,
        'data',
        'store() requires a client-generated "${table.primaryKey}" value: an '
        'offline create writes to the local table before any server '
        'round-trip, so the primary key must be present in the data map '
        '(e.g. a UUID generated on-device). See this class\'s dartdoc.',
      );
    }
  }

  Future<void> _enqueueSync(String method, String path, Object? data) async {
    await queue.enqueue(OfflineRequest(
      id: '${DateTime.now().microsecondsSinceEpoch}-$path',
      method: method,
      path: path,
      data: data,
      createdAt: DateTime.now(),
    ));
    // If we're already online, kick a flush now; otherwise ConnectivityService's
    // onOnline hook (wired by VeloraOfflinePlugin) flushes on reconnect.
    if (connectivity.isOnline.value) {
      unawaited(queue.flush());
    }
  }
}
