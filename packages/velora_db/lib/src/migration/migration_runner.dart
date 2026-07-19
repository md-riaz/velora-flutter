import 'package:sqflite_common/sqlite_api.dart';

import 'velora_migration.dart';

/// Drives a list of [VeloraMigration]s deterministically against sqflite's
/// `onCreate` / `onUpgrade` lifecycle hooks.
///
/// Migrations are sorted by [VeloraMigration.version] ascending at
/// construction time; a duplicate version throws [ArgumentError] immediately
/// rather than silently running migrations in an unspecified order.
class VeloraMigrationRunner {
  /// Migrations sorted by [VeloraMigration.version], ascending.
  final List<VeloraMigration> migrations;

  VeloraMigrationRunner(List<VeloraMigration> migrations)
      : migrations = _sorted(migrations);

  static List<VeloraMigration> _sorted(List<VeloraMigration> migrations) {
    final sorted = [...migrations]
      ..sort((a, b) => a.version.compareTo(b.version));
    final seen = <int>{};
    for (final migration in sorted) {
      if (!seen.add(migration.version)) {
        throw ArgumentError(
          'Duplicate VeloraMigration version: ${migration.version}. '
          'Each migration passed to a VeloraDatabase must have a unique version.',
        );
      }
    }
    return List.unmodifiable(sorted);
  }

  /// The highest known migration version, or `0` if there are no migrations.
  int get maxVersion => migrations.isEmpty ? 0 : migrations.last.version;

  /// Runs every migration's [VeloraMigration.up], in version order. Wire
  /// this as sqflite's `onCreate` hook for a brand-new database.
  Future<void> onCreate(Database db, int version) async {
    for (final migration in migrations) {
      await migration.up(db);
    }
  }

  /// Runs [VeloraMigration.up] for every migration whose version falls in
  /// `(oldVersion, newVersion]`, in version order. Wire this as sqflite's
  /// `onUpgrade` hook.
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final migration in migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await migration.up(db);
      }
    }
  }

  /// Runs [VeloraMigration.down] for every migration whose version falls in
  /// `(newVersion, oldVersion]`, in descending version order. Not wired by
  /// default (sqflite has no `onDowngrade` hook unless explicitly opted
  /// into) — available for callers that manage downgrades themselves.
  Future<void> onDowngrade(Database db, int oldVersion, int newVersion) async {
    for (final migration in migrations.reversed) {
      if (migration.version > newVersion && migration.version <= oldVersion) {
        await migration.down(db);
      }
    }
  }
}
