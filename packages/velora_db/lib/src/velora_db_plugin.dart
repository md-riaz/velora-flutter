import 'package:sqflite_common/sqlite_api.dart';
import 'package:velora/velora.dart';

import 'migration/velora_migration.dart';
import 'query/velora_table.dart';
import 'velora_database.dart';

/// A valid, unquoted SQL identifier — used to allowlist the developer-
/// supplied table names in [VeloraDbPlugin.clearOnLogout] before they're
/// interpolated into a `DELETE FROM <table>` statement (table names can't be
/// bound as query parameters the way values can).
final _validIdentifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// An official Velora plugin that opens a sqflite-backed [VeloraDatabase] and
/// registers it for the app's lifetime.
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
  final DatabaseFactory? factory;

  /// Table names whose rows are deleted on logout (`DELETE FROM <table>` —
  /// all rows, schema and connection preserved). Use this for simple
  /// "wipe the whole table" cases; for anything more selective (a `WHERE`
  /// clause, a `VACUUM`, etc.) use [onLogout] instead or in addition.
  final List<String> clearOnLogout;

  /// Optional callback for logout-time data clearing that needs more nuance
  /// than a blanket per-table delete (selective/per-user `WHERE` deletes,
  /// vacuuming, etc.). Runs after [clearOnLogout]'s deletes.
  final Future<void> Function(Database db)? onLogout;

  VeloraDbPlugin({
    this.databaseName = 'app.db',
    this.version = 1,
    this.migrations = const [],
    this.factory,
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
      factory: factory,
    ).open();
    context.put<VeloraDatabase>(db);

    if (clearOnLogout.isNotEmpty || onLogout != null) {
      for (final table in clearOnLogout) {
        if (!_validIdentifier.hasMatch(table)) {
          throw ArgumentError.value(
            table,
            'clearOnLogout',
            'Invalid table name',
          );
        }
      }

      context.onBeforeLogout(() async {
        for (final table in clearOnLogout) {
          await db.db.delete(table);
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

  static Database get db => instance.db;

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
