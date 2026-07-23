import 'package:velora_db/velora_db.dart';

/// The demo's whole schema: one migration creating the `articles` table that
/// backs `VeloraCachedRepository`'s local read-through cache.
///
/// Unlike `velora_chat`'s schema (the source of truth for every write in
/// that app), this table only ever holds a *copy* of whatever the remote
/// API last returned — `VeloraCachedRepository` upserts into it after every
/// successful `index()`/`show()` call, and reads from it only when the
/// remote call fails with an offline-shaped error.
class CreateCatalogSchema extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        author TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<void> down(VeloraMigrationContext context) async {
    await context.execute('DROP TABLE IF EXISTS articles');
  }
}
