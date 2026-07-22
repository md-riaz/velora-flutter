import 'package:drift/drift.dart';
import 'package:get/get.dart';

import 'driver/db_factory.dart';
import 'migration/migration_runner.dart';
import 'migration/velora_migration.dart';
import 'velora_sql_database.dart';

/// Opens and owns the app's local, reactive drift database, applying
/// [migrations] deterministically via [VeloraMigrationRunner] on create/
/// upgrade.
///
/// Works identically on native (a drift `NativeDatabase`, backed by
/// `package:sqlite3`) and Web (a drift `WasmDatabase`, persisting to OPFS/
/// IndexedDB) -- see `driver/db_factory.dart` for the conditional-import seam
/// that picks the right [QueryExecutor] for the current platform. Tests
/// inject their own [executor] (typically `NativeDatabase.memory()`) to run
/// headless, without any platform channel.
///
/// The database is intentionally **schema-less** from drift's point of view
/// (see [VeloraSqlDatabase]): there are no drift-generated table classes and
/// no `build_runner`. Every table is created by a [VeloraMigration] via raw
/// SQL, and every read/write in this package goes through drift's
/// `customSelect`/`customStatement` APIs plus its `tableUpdates`/
/// `notifyUpdates` stream-invalidation primitives, which is also what makes
/// `VeloraTable.watchAll()`/`watchQuery()`/`watchFind()` possible.
class VeloraDatabase extends GetxService {
  final String databaseName;
  final int version;
  final List<VeloraMigration> migrations;

  /// Optional injected executor, overriding the platform default. Used by
  /// tests (e.g. `NativeDatabase.memory()` from `package:drift/native.dart`);
  /// real apps normally leave this `null`.
  final QueryExecutor? executor;

  final VeloraMigrationRunner _runner;
  VeloraSqlDatabase? _db;

  VeloraDatabase({
    required this.databaseName,
    required this.version,
    required this.migrations,
    this.executor,
  }) : _runner = VeloraMigrationRunner(migrations);

  /// The open [VeloraSqlDatabase] handle. Only valid after [open] has
  /// completed.
  VeloraSqlDatabase get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'VeloraDatabase.db was accessed before open() completed for '
        '"$databaseName".',
      );
    }
    return database;
  }

  /// Opens the database via the injected [executor], or the platform default
  /// ([defaultVeloraDbExecutor]) when none was supplied, wiring the migration
  /// runner to drift's `onCreate` / `onUpgrade` (see [VeloraSqlDatabase]).
  /// Returns `this` for fluent chaining, mirroring
  /// `VeloraStorageService.init()` / `OfflineRequestQueue.load()`.
  Future<VeloraDatabase> open() async {
    final queryExecutor = executor ?? defaultVeloraDbExecutor(databaseName);
    final database = VeloraSqlDatabase(
      queryExecutor,
      schemaVersion: version,
      runner: _runner,
    );
    // Force the connection open (and any pending migrations to run) now,
    // rather than lazily on the first query -- so open() truly doesn't
    // complete until migrations have finished, matching the old sqflite
    // factory's openDatabase() contract. Keep `database` local until this
    // succeeds: if a migration throws, `_db` must never be left pointing at
    // a half-open/broken connection, and the failed connection must be
    // closed rather than leaked.
    try {
      await database.doWhenOpened((_) async {});
    } catch (_) {
      await database.close();
      rethrow;
    }
    _db = database;
    return this;
  }

  /// Closes the underlying database handle. The connection is app-lifetime
  /// by convention (see `VeloraDbPlugin`) — this exists for tests and
  /// explicit app-shutdown paths, not for per-user teardown.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
