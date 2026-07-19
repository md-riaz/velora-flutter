import 'package:sqflite_common/sqlite_api.dart';

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
  Future<void> up(Database db);

  /// Reverts this migration's schema changes. Optional — defaults to a
  /// no-op, since most apps never need to roll a schema back.
  Future<void> down(Database db) async {}
}
