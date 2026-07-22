import 'package:drift/drift.dart';

/// An engine-agnostic handle passed to [VeloraMigration.up] / [.down],
/// wrapping just enough of the underlying drift database to run raw SQL --
/// migrations stay plain SQL strings and never need to know they're running
/// against drift (or, before this package's engine swap, sqflite).
class VeloraMigrationContext {
  final GeneratedDatabase _db;

  const VeloraMigrationContext(this._db);

  /// Executes a raw SQL statement (DDL like `CREATE TABLE`/`ALTER TABLE`, or
  /// a DML statement), optionally binding positional `?` placeholders to
  /// [args].
  Future<void> execute(String sql, [List<Object?> args = const []]) {
    return _db.customStatement(sql, args);
  }
}

/// A single, versioned schema change.
///
/// Implement one class per schema revision. [version] must be unique among
/// the migrations passed to a given `VeloraDatabase` — see
/// `VeloraMigrationRunner`, which sorts migrations by [version] and rejects
/// duplicates.
abstract class VeloraMigration {
  const VeloraMigration();

  /// This migration's schema version.
  int get version;

  /// Applies this migration's schema changes.
  Future<void> up(VeloraMigrationContext context);

  /// Reverts this migration's schema changes. Optional — defaults to a
  /// no-op, since most apps never need to roll a schema back.
  Future<void> down(VeloraMigrationContext context) async {}
}
