import 'package:drift/drift.dart';

import 'migration/migration_runner.dart';
import 'migration/velora_migration.dart';

/// The concrete, **schema-less** drift [GeneratedDatabase] every
/// `VeloraDatabase` wraps.
///
/// It declares an empty schema ([allTables] / [allSchemaEntities] are always
/// `const []`) -- there are no drift-generated table classes and no
/// `build_runner`/codegen involved. Every table is created by a
/// [VeloraMigration] via raw SQL (through [VeloraMigrationContext]), and
/// every read/write elsewhere in this package goes through drift's
/// `customSelect` / `customStatement` / `batch` APIs rather than drift's
/// typed Dart query builder.
///
/// Schema changes are still driven by drift's own `PRAGMA user_version`
/// machinery: [schemaVersion] is the highest [VeloraMigration.version] known
/// to the [VeloraMigrationRunner], and [migration] wires `onCreate` /
/// `onUpgrade` to the runner. Notably, drift's `onUpgrade` fires for *both*
/// upgrades and downgrades (`from`/`to` in either order), so a single wire-up
/// covers what sqflite needed a separate `onDowngrade` hook for.
class VeloraSqlDatabase extends GeneratedDatabase {
  final int _schemaVersion;
  final VeloraMigrationRunner _runner;

  VeloraSqlDatabase(
    super.executor, {
    required int schemaVersion,
    required VeloraMigrationRunner runner,
  }) : _schemaVersion = schemaVersion,
       _runner = runner;

  @override
  int get schemaVersion => _schemaVersion;

  @override
  Iterable<TableInfo> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => _runner.onCreate(
      VeloraMigrationContext(m.database),
      schemaVersion,
    ),
    onUpgrade: (m, from, to) async {
      final context = VeloraMigrationContext(m.database);
      if (to > from) {
        await _runner.onUpgrade(context, from, to);
      } else if (to < from) {
        await _runner.onDowngrade(context, from, to);
      }
    },
  );
}
