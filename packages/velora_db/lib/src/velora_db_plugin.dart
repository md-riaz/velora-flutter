import 'package:drift/drift.dart';
import 'package:velora/velora.dart';

import 'migration/velora_migration.dart';
import 'query/sql_identifier.dart';
import 'query/velora_table.dart';
import 'velora_database.dart';
import 'velora_sql_database.dart';

/// An official Velora plugin that opens a drift-backed, reactive
/// [VeloraDatabase] and registers it for the app's lifetime.
///
/// ```dart
/// await Velora.boot(
///   config: myConfig,
///   plugins: [
///     VeloraDbPlugin(
///       databaseName: 'app.db',
///       version: 1,
///       migrations: [CreateTodosTable()],
///       clearOnLogout: ['messages', 'permission_cache'],
///     ),
///   ],
/// );
/// ```
///
/// [databaseName], [version], and [migrations] all have defaults —
/// `VeloraDbPlugin()` alone is a valid, installable plugin that opens an
/// empty database named `app.db` at version 1 (an empty migration list is a
/// no-op `onCreate`). This is what `velora install velora_db` wires into
/// `Velora.boot()`; add real migrations once you know what tables you need.
///
/// ## Connection vs. data lifetime
///
/// The database **connection** is app-lifetime: it is opened once in
/// [register] and is never closed on logout, unlike
/// `VeloraOfflinePlugin`'s queue. But some of the **data** in it is
/// user-scoped — a permission cache, cached message/SMS history, or other
/// per-account rows must not leak to the next account on a shared device.
/// [clearOnLogout] and [onLogout] exist for exactly that: they run during the
/// logout `beforeLogout` phase, deleting rows (schema and connection
/// untouched) rather than tearing anything down.
class VeloraDbPlugin extends VeloraPlugin {
  final String databaseName;
  final int version;
  final List<VeloraMigration> migrations;

  /// Optional injected drift [QueryExecutor], overriding the platform
  /// default. Used by tests (e.g. `NativeDatabase.memory()`); real apps
  /// normally leave this `null`.
  final QueryExecutor? executor;

  /// Table names whose rows are deleted on logout (`DELETE FROM "<table>"` —
  /// all rows, schema and connection preserved), all inside a single
  /// transaction so a failure partway through rolls back every delete rather
  /// than leaving some tables cleared and others not. Use this for simple
  /// "wipe the whole table" cases; for anything more selective (a `WHERE`
  /// clause, a `VACUUM`, etc.) use [onLogout] instead or in addition.
  ///
  /// Table names are allowlisted against [isValidSqlIdentifier] (see
  /// [register]) before being interpolated into the (double-quoted)
  /// `DELETE FROM` statement -- they can't be bound as query parameters the
  /// way values can.
  final List<String> clearOnLogout;

  /// Optional callback for logout-time data clearing that needs more nuance
  /// than a blanket per-table delete (selective/per-user `WHERE` deletes,
  /// vacuuming, etc.). Runs after [clearOnLogout]'s deletes.
  final Future<void> Function(VeloraSqlDatabase db)? onLogout;

  VeloraDbPlugin({
    this.databaseName = 'app.db',
    this.version = 1,
    this.migrations = const [],
    this.executor,
    this.clearOnLogout = const [],
    this.onLogout,
  });

  @override
  String get name => 'velora_db';

  @override
  Future<void> register(VeloraContext context) async {
    final db = await VeloraDatabase(
      databaseName: databaseName,
      version: version,
      migrations: migrations,
      executor: executor,
    ).open();
    context.put<VeloraDatabase>(db);

    if (clearOnLogout.isNotEmpty || onLogout != null) {
      for (final table in clearOnLogout) {
        validateSqlIdentifier(table, argumentName: 'clearOnLogout');
      }

      context.onBeforeLogout(() async {
        // Run every clearOnLogout delete inside a single transaction: if a
        // later DELETE throws, earlier ones roll back too, rather than
        // leaving some tables cleared and others not -- logout's caller
        // swallows exceptions from this hook, so a partial failure here
        // would otherwise complete "successfully" with residual data.
        final clearedTables = <String>{};
        await db.db.transaction(() async {
          for (final table in clearOnLogout) {
            // Table name is double-quoted as a SQL identifier (not a bound
            // parameter -- identifiers can't be bound) so a valid-but-SQL-
            // keyword table name (e.g. `order`) still works; the
            // validateSqlIdentifier() allowlist above already rejects
            // anything a `"`-quoted identifier wouldn't safely contain.
            final affected = await db.db.customUpdate(
              'DELETE FROM "$table"',
              updateKind: UpdateKind.delete,
            );
            if (affected > 0) {
              clearedTables.add(table);
            }
          }
        });
        // Notify only after the transaction has committed, so watchers never
        // see a "table changed" event for a delete that ends up rolled back.
        if (clearedTables.isNotEmpty) {
          db.db.notifyUpdates({
            for (final table in clearedTables)
              TableUpdate(table, kind: UpdateKind.delete),
          });
        }
        await onLogout?.call(db.db);
      });
    }
  }
}

/// Package-level facade for the database [VeloraDbPlugin] registers. Kept
/// out of core `Velora` so the framework stays agnostic of this plugin.
class VeloraDb {
  const VeloraDb._();

  static VeloraDatabase get instance => Get.find<VeloraDatabase>();

  static VeloraSqlDatabase get db => instance.db;

  /// Binds a [VeloraTable] to the registered [VeloraDatabase].
  static VeloraTable<T, ID> table<T, ID>({
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    required Map<String, dynamic> Function(T) toMap,
    String primaryKey = 'id',
  }) {
    return VeloraTable<T, ID>(
      db: db,
      table: table,
      fromMap: fromMap,
      toMap: toMap,
      primaryKey: primaryKey,
    );
  }
}
