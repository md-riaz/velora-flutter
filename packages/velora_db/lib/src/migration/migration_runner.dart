import 'velora_migration.dart';

/// Drives a list of [VeloraMigration]s deterministically against drift's
/// `MigrationStrategy` (`onCreate` / `onUpgrade`, the latter also covering
/// downgrades -- see [onDowngrade]) lifecycle hooks.
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
  /// this as drift's `MigrationStrategy.onCreate` for a brand-new database.
  Future<void> onCreate(VeloraMigrationContext context, int version) async {
    for (final migration in migrations) {
      await migration.up(context);
    }
  }

  /// Runs [VeloraMigration.up] for every migration whose version falls in
  /// `(oldVersion, newVersion]`, in version order. Wire this as drift's
  /// `MigrationStrategy.onUpgrade` when `newVersion > oldVersion`.
  Future<void> onUpgrade(
    VeloraMigrationContext context,
    int oldVersion,
    int newVersion,
  ) async {
    for (final migration in migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await migration.up(context);
      }
    }
  }

  /// Runs [VeloraMigration.down] for every migration whose version falls in
  /// `(newVersion, oldVersion]`, in descending version order. Wire this as
  /// drift's `MigrationStrategy.onUpgrade` when `newVersion < oldVersion`
  /// (drift's `onUpgrade` callback handles both upgrades and downgrades --
  /// unlike sqflite, there's no separate `onDowngrade` hook to wire).
  Future<void> onDowngrade(
    VeloraMigrationContext context,
    int oldVersion,
    int newVersion,
  ) async {
    for (final migration in migrations.reversed) {
      if (migration.version > newVersion && migration.version <= oldVersion) {
        await migration.down(context);
      }
    }
  }
}
