import 'migration/velora_migration.dart';

/// Declarative database schema shared between app startup
/// (`VeloraDbPlugin.fromSchema`) and in-memory test instances
/// (`VeloraDatabase.inMemory`).
class VeloraDbSchema {
  final String databaseName;
  final int version;
  final List<VeloraMigration> migrations;
  final List<String> clearOnLogout;

  const VeloraDbSchema({
    this.databaseName = 'app.db',
    this.version = 1,
    this.migrations = const [],
    this.clearOnLogout = const [],
  });
}
