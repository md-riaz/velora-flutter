import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, Variable;
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import '../contracts/realtime_port.dart';
import '../diagnostics/diagnostics_log.dart';
import '../models/work_item.dart';

/// Migration creating durable work items, outbox mutations, cursors, and
/// processed event IDs tables.
class CreateReadinessTablesMigration extends VeloraMigration {
  const CreateReadinessTablesMigration();

  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE IF NOT EXISTS work_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL,
        version INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        idempotency_key TEXT,
        server_title TEXT,
        last_error TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await context.execute('''
      CREATE TABLE IF NOT EXISTS outbox_mutations (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL,
        base_version INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await context.execute('''
      CREATE TABLE IF NOT EXISTS cursors (
        stream_key TEXT PRIMARY KEY,
        cursor_value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await context.execute('''
      CREATE TABLE IF NOT EXISTS processed_events (
        event_id TEXT PRIMARY KEY,
        cursor_value TEXT NOT NULL,
        processed_at TEXT NOT NULL
      )
    ''');
  }
}

/// Declarative database schema shared between production boot and tests.
const VeloraDbSchema readinessDbSchema = VeloraDbSchema(
  databaseName: 'desktop_readiness.db',
  version: 1,
  migrations: [CreateReadinessTablesMigration()],
);

/// Summary of a single outbox flush pass.
final class OutboxFlushReport {
  final int applied;
  final int conflicts;
  final bool pausedUnauthorized;
  final bool unreachable;

  const OutboxFlushReport({
    this.applied = 0,
    this.conflicts = 0,
    this.pausedUnauthorized = false,
    this.unreachable = false,
  });
}

/// Durable local store for [WorkItem]s, outbox mutations, realtime cursors,
/// and deduplicated event IDs.
class ReadinessWorkStore implements ReadinessCursorStore, ReadinessReconciler {
  static const String _defaultStreamKey = 'work_items';

  final VeloraDatabase database;
  final ToggleConnectivitySource connectivity;
  final ReadinessRemoteGateway gateway;
  final ReadinessDiagnosticsLog diagnostics;
  final DateTime Function() _now;

  late final VeloraTable<WorkItem, String> _itemsTable;
  int _keyCounter = 0;

  ReadinessWorkStore({
    required this.database,
    required this.connectivity,
    required this.gateway,
    required this.diagnostics,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _itemsTable = VeloraTable<WorkItem, String>(
      db: database.db,
      table: 'work_items',
      fromMap: WorkItem.fromMap,
      toMap: (item) => item.toMap(),
    );
  }

  List<WorkItem> _sortItems(List<WorkItem> items) => items
    ..sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      return priority != 0 ? priority : a.id.compareTo(b.id);
    });

  /// Reactive stream of all work items ordered by priority descending, then ID.
  Stream<List<WorkItem>> watchItems() => _itemsTable.watchAll().map(_sortItems);

  /// Loads all work items once in the same order as [watchItems].
  Future<List<WorkItem>> loadItems() async =>
      _sortItems(await _itemsTable.all());

  /// Looks up a single [WorkItem] by [id].
  Future<WorkItem?> findItem(String id) => _itemsTable.find(id);

  /// Seeds default items if the `work_items` table is currently empty.
  Future<void> seedDefaultsIfEmpty() async {
    final existing = await loadItems();
    if (existing.isNotEmpty) return;

    final now = _now().toUtc();
    final defaults = [
      WorkItem(
        id: 'WI-101',
        title: 'Verify tray close-to-background lifecycle',
        priority: 3,
        version: 1,
        syncStatus: SyncStatus.synced,
        updatedAt: now,
      ),
      WorkItem(
        id: 'WI-102',
        title: 'Audit outbox idempotency across restart',
        priority: 2,
        version: 1,
        syncStatus: SyncStatus.synced,
        updatedAt: now,
      ),
      WorkItem(
        id: 'WI-103',
        title: 'Validate sleep/resume cursor reconciliation',
        priority: 1,
        version: 1,
        syncStatus: SyncStatus.synced,
        updatedAt: now,
      ),
    ];

    for (final item in defaults) {
      await _itemsTable.insert(item.toMap());
    }
    diagnostics.record(
      'store',
      'Seeded initial work items',
      metadata: {'count': defaults.length},
    );
  }

  /// Inserts or replaces a [WorkItem] directly (used for local setup/seeding).
  Future<void> putItem(WorkItem item) async {
    await _itemsTable.insert(item.toMap());
  }

  /// Persists a local edit to `work_items` and enqueues an idempotent
  /// `outbox_mutations` row inside a single transaction.
  Future<WorkItem> enqueueMutation({
    required String itemId,
    required String title,
    required int priority,
    String? idempotencyKey,
  }) async {
    final existing = await findItem(itemId);
    final now = _now().toUtc();
    final key =
        idempotencyKey ??
        existing?.idempotencyKey ??
        'mut-$itemId-${now.microsecondsSinceEpoch}-${++_keyCounter}';
    final baseVersion = existing?.version ?? 0;

    final updated = WorkItem(
      id: itemId,
      title: title,
      priority: priority,
      version: baseVersion,
      syncStatus: SyncStatus.pending,
      idempotencyKey: key,
      serverTitle: existing?.serverTitle,
      lastError: null,
      updatedAt: now,
    );

    await database.db.transaction(() async {
      await database.db.customStatement(
        '''
        INSERT OR REPLACE INTO work_items
          (id, title, priority, version, sync_status, idempotency_key, server_title, last_error, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          updated.id,
          updated.title,
          updated.priority,
          updated.version,
          updated.syncStatus.name,
          updated.idempotencyKey,
          updated.serverTitle,
          updated.lastError,
          updated.updatedAt.toUtc().toIso8601String(),
        ],
      );

      await database.db.customStatement(
        '''
        INSERT OR REPLACE INTO outbox_mutations
          (id, item_id, idempotency_key, title, priority, base_version, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          key,
          updated.id,
          key,
          updated.title,
          updated.priority,
          baseVersion,
          now.toIso8601String(),
        ],
      );
    });
    database.db.notifyUpdates({const TableUpdate('work_items')});

    diagnostics.record(
      'outbox',
      'Enqueued durable mutation',
      metadata: {'itemId': itemId, 'idempotencyKey': key},
    );
    return updated;
  }

  /// Number of mutations currently waiting in `outbox_mutations`.
  Future<int> pendingOutboxCount() async {
    final rows = await database.db
        .customSelect('SELECT COUNT(*) AS cnt FROM outbox_mutations')
        .get();
    if (rows.isEmpty) return 0;
    return (rows.first.data['cnt'] as num).toInt();
  }

  /// Flushes queued outbox mutations in FIFO order.
  ///
  /// Stops immediately on unreachable endpoints or permanent auth failures
  /// without spinning in a retry loop.
  Future<OutboxFlushReport> flushOutbox() async {
    final online = await connectivity.isConnected();
    if (!online) {
      diagnostics.record('outbox', 'Flush skipped: offline');
      return const OutboxFlushReport(unreachable: true);
    }

    final reachable = await gateway.checkReachability();
    if (!reachable) {
      diagnostics.record('outbox', 'Flush paused: endpoint unreachable');
      return const OutboxFlushReport(unreachable: true);
    }

    final rows = await database.db
        .customSelect(
          'SELECT * FROM outbox_mutations ORDER BY created_at ASC, id ASC',
        )
        .get();

    var applied = 0;
    var conflicts = 0;

    for (final row in rows) {
      final mutationId = row.data['id'] as String;
      final itemId = row.data['item_id'] as String;
      final idempotencyKey = row.data['idempotency_key'] as String;
      final title = row.data['title'] as String;
      final priority = (row.data['priority'] as num).toInt();
      final baseVersion = (row.data['base_version'] as num).toInt();

      final current = await findItem(itemId);
      final candidate =
          (current ??
                  WorkItem(
                    id: itemId,
                    title: title,
                    priority: priority,
                    version: baseVersion,
                    syncStatus: SyncStatus.synchronizing,
                    idempotencyKey: idempotencyKey,
                    updatedAt: _now().toUtc(),
                  ))
              .copyWith(
                title: title,
                priority: priority,
                syncStatus: SyncStatus.synchronizing,
                idempotencyKey: idempotencyKey,
              );
      await _itemsTable.insert(candidate.toMap());

      final result = await gateway.pushMutation(
        item: candidate,
        idempotencyKey: idempotencyKey,
      );

      switch (result.outcome) {
        case ReadinessPushOutcome.applied:
          final synced =
              result.serverItem ??
              candidate.copyWith(
                version: candidate.version + 1,
                syncStatus: SyncStatus.synced,
                clearIdempotencyKey: true,
                clearServerTitle: true,
                clearLastError: true,
                updatedAt: _now().toUtc(),
              );
          await database.db.transaction(() async {
            await database.db.customStatement(
              '''
              INSERT OR REPLACE INTO work_items
                (id, title, priority, version, sync_status, idempotency_key, server_title, last_error, updated_at)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''',
              [
                synced.id,
                synced.title,
                synced.priority,
                synced.version,
                synced.syncStatus.name,
                synced.idempotencyKey,
                synced.serverTitle,
                synced.lastError,
                synced.updatedAt.toUtc().toIso8601String(),
              ],
            );
            await database.db.customStatement(
              'DELETE FROM outbox_mutations WHERE id = ?',
              [mutationId],
            );
          });
          database.db.notifyUpdates({const TableUpdate('work_items')});
          applied++;
          diagnostics.record(
            'outbox',
            'Mutation applied idempotently',
            metadata: {'itemId': itemId, 'version': synced.version},
          );

        case ReadinessPushOutcome.unreachable:
          final reverted = candidate.copyWith(
            syncStatus: SyncStatus.pending,
            lastError: result.errorMessage,
          );
          await _itemsTable.insert(reverted.toMap());
          diagnostics.record(
            'outbox',
            'Mutation deferred: endpoint unreachable',
            metadata: {'itemId': itemId},
          );
          return OutboxFlushReport(
            applied: applied,
            conflicts: conflicts,
            unreachable: true,
          );

        case ReadinessPushOutcome.conflict:
          final conflicted = candidate.copyWith(
            syncStatus: SyncStatus.conflict,
            serverTitle: result.serverTitle,
            lastError: result.errorMessage ?? 'Conflict requires resolution',
            updatedAt: _now().toUtc(),
          );
          await database.db.transaction(() async {
            await database.db.customStatement(
              '''
              INSERT OR REPLACE INTO work_items
                (id, title, priority, version, sync_status, idempotency_key, server_title, last_error, updated_at)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''',
              [
                conflicted.id,
                conflicted.title,
                conflicted.priority,
                conflicted.version,
                conflicted.syncStatus.name,
                conflicted.idempotencyKey,
                conflicted.serverTitle,
                conflicted.lastError,
                conflicted.updatedAt.toUtc().toIso8601String(),
              ],
            );
            await database.db.customStatement(
              'DELETE FROM outbox_mutations WHERE id = ?',
              [mutationId],
            );
          });
          database.db.notifyUpdates({const TableUpdate('work_items')});
          conflicts++;
          diagnostics.record(
            'outbox',
            'Conflict detected; awaiting explicit resolution',
            metadata: {'itemId': itemId},
          );

        case ReadinessPushOutcome.unauthorized:
          final failed = candidate.copyWith(
            syncStatus: SyncStatus.permanentFailure,
            lastError: result.errorMessage ?? 'Unauthorized',
            updatedAt: _now().toUtc(),
          );
          await _itemsTable.insert(failed.toMap());
          diagnostics.record(
            'auth',
            'Outbox paused due to permanent auth failure',
            metadata: {'itemId': itemId},
          );
          return OutboxFlushReport(
            applied: applied,
            conflicts: conflicts,
            pausedUnauthorized: true,
          );
      }
    }

    return OutboxFlushReport(applied: applied, conflicts: conflicts);
  }

  /// Resolves a conflict by keeping the local title and re-enqueuing a fresh
  /// idempotent mutation.
  Future<WorkItem?> resolveConflictKeepLocal(String itemId) async {
    final item = await findItem(itemId);
    if (item == null || item.syncStatus != SyncStatus.conflict) return item;
    final cleared = item.copyWith(
      clearServerTitle: true,
      clearLastError: true,
      clearIdempotencyKey: true,
    );
    await _itemsTable.insert(cleared.toMap());
    final reQueued = await enqueueMutation(
      itemId: item.id,
      title: item.title,
      priority: item.priority,
    );
    diagnostics.record(
      'conflict',
      'Resolved conflict by keeping local edit',
      metadata: {'itemId': itemId},
    );
    return reQueued;
  }

  /// Resolves a conflict by accepting the server's title and clearing outbox
  /// state.
  Future<WorkItem?> resolveConflictAcceptServer(String itemId) async {
    final item = await findItem(itemId);
    if (item == null || item.syncStatus != SyncStatus.conflict) return item;
    final resolved = item.copyWith(
      title: item.serverTitle ?? item.title,
      version: item.version + 1,
      syncStatus: SyncStatus.synced,
      clearIdempotencyKey: true,
      clearServerTitle: true,
      clearLastError: true,
      updatedAt: _now().toUtc(),
    );
    await database.db.transaction(() async {
      await database.db.customStatement(
        '''
        INSERT OR REPLACE INTO work_items
          (id, title, priority, version, sync_status, idempotency_key, server_title, last_error, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          resolved.id,
          resolved.title,
          resolved.priority,
          resolved.version,
          resolved.syncStatus.name,
          resolved.idempotencyKey,
          resolved.serverTitle,
          resolved.lastError,
          resolved.updatedAt.toUtc().toIso8601String(),
        ],
      );
      await database.db.customStatement(
        'DELETE FROM outbox_mutations WHERE item_id = ?',
        [itemId],
      );
    });
    database.db.notifyUpdates({const TableUpdate('work_items')});
    diagnostics.record(
      'conflict',
      'Resolved conflict by accepting server state',
      metadata: {'itemId': itemId},
    );
    return resolved;
  }

  @override
  Future<String?> loadCursor() async {
    final rows = await database.db
        .customSelect(
          'SELECT cursor_value FROM cursors WHERE stream_key = ?',
          variables: [const Variable<String>(_defaultStreamKey)],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.data['cursor_value'] as String?;
  }

  @override
  Future<void> saveCursor(String cursor) async {
    await database.db.customStatement(
      '''
      INSERT OR REPLACE INTO cursors (stream_key, cursor_value, updated_at)
      VALUES (?, ?, ?)
      ''',
      [_defaultStreamKey, cursor, _now().toUtc().toIso8601String()],
    );
  }

  /// Checks whether [eventId] has already been processed in SQLite.
  Future<bool> hasProcessedEvent(String eventId) async {
    final rows = await database.db
        .customSelect(
          'SELECT event_id FROM processed_events WHERE event_id = ?',
          variables: [Variable<String>(eventId)],
        )
        .get();
    return rows.isNotEmpty;
  }

  @override
  Future<int> reconcile({
    required String? sinceCursor,
    required List<ReadinessRealtimeEvent> events,
  }) async {
    if (events.isEmpty) return 0;

    var appliedCount = 0;
    String? latestCursor = sinceCursor;

    for (final event in events) {
      if (await hasProcessedEvent(event.id)) {
        diagnostics.record(
          'reconcile',
          'Skipped duplicate realtime event',
          metadata: {'eventId': event.id, 'cursor': event.cursor},
        );
        continue;
      }

      final existing = await findItem(event.item.id);
      await database.db.transaction(() async {
        // Do not overwrite an active local pending/conflict item silently.
        if (existing == null ||
            (existing.syncStatus != SyncStatus.pending &&
                existing.syncStatus != SyncStatus.conflict)) {
          final merged = event.item.copyWith(
            syncStatus: SyncStatus.synced,
            clearIdempotencyKey: true,
            clearServerTitle: true,
            clearLastError: true,
          );
          await database.db.customStatement(
            '''
            INSERT OR REPLACE INTO work_items
              (id, title, priority, version, sync_status, idempotency_key, server_title, last_error, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              merged.id,
              merged.title,
              merged.priority,
              merged.version,
              merged.syncStatus.name,
              merged.idempotencyKey,
              merged.serverTitle,
              merged.lastError,
              merged.updatedAt.toUtc().toIso8601String(),
            ],
          );
        }

        await database.db.customStatement(
          '''
          INSERT OR IGNORE INTO processed_events (event_id, cursor_value, processed_at)
          VALUES (?, ?, ?)
          ''',
          [event.id, event.cursor, _now().toUtc().toIso8601String()],
        );
      });

      latestCursor = event.cursor;
      appliedCount++;
    }

    if (latestCursor != null) {
      await saveCursor(latestCursor);
    }
    if (appliedCount > 0) {
      database.db.notifyUpdates({const TableUpdate('work_items')});
      diagnostics.record(
        'reconcile',
        'Reconciled remote events',
        metadata: {'applied': appliedCount, 'cursor': latestCursor},
      );
    }
    return appliedCount;
  }
}
