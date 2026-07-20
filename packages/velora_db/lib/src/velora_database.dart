import 'package:get/get.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'driver/db_factory.dart';
import 'migration/migration_runner.dart';
import 'migration/velora_migration.dart';

/// Opens and owns the app's local sqflite database, applying [migrations]
/// deterministically via [VeloraMigrationRunner] on create/upgrade.
///
/// Works identically on native (via `sqflite`) and Web (via
/// `sqflite_common_ffi_web`, which persists to IndexedDB transparently) —
/// see `driver/db_factory.dart` for the conditional-import seam that picks
/// the right [DatabaseFactory] for the current platform. Tests inject their
/// own [factory] (e.g. `sqflite_common_ffi`'s `databaseFactoryFfi`, typically
/// combined with `inMemoryDatabasePath`) to run headless, without any
/// platform channel.
class VeloraDatabase extends GetxService {
  final String databaseName;
  final int version;
  final List<VeloraMigration> migrations;

  /// Optional injected factory, overriding the platform default. Used by
  /// tests; real apps normally leave this `null`.
  final DatabaseFactory? factory;

  final VeloraMigrationRunner _runner;
  Database? _db;

  VeloraDatabase({
    required this.databaseName,
    required this.version,
    required this.migrations,
    this.factory,
  }) : _runner = VeloraMigrationRunner(migrations);

  /// The open [Database] handle. Only valid after [open] has completed.
  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'VeloraDatabase.db was accessed before open() completed for '
        '"$databaseName".',
      );
    }
    return database;
  }

  /// Opens the database via the injected [factory], or the platform default
  /// ([defaultVeloraDbFactory]) when none was supplied, wiring the migration
  /// runner to `onCreate` / `onUpgrade`. Returns `this` for fluent chaining,
  /// mirroring `VeloraStorageService.init()` / `OfflineRequestQueue.load()`.
  Future<VeloraDatabase> open() async {
    final dbFactory = factory ?? defaultVeloraDbFactory();
    _db = await dbFactory.openDatabase(
      databaseName,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, version) => _runner.onCreate(db, version),
        onUpgrade: (db, oldVersion, newVersion) =>
            _runner.onUpgrade(db, oldVersion, newVersion),
        onDowngrade: (db, oldVersion, newVersion) =>
            _runner.onDowngrade(db, oldVersion, newVersion),
      ),
    );
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
