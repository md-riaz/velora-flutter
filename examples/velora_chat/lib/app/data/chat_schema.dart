import 'package:velora_db/velora_db.dart';

/// The demo's whole schema: one migration creating both chat tables.
///
/// `conversations` holds one row per thread with a denormalized preview
/// (`last_message` / `last_at`) so the conversations list never needs to
/// join against `messages`. `messages` holds every message in every
/// conversation, newest last within a thread (ordered by `created_at`).
class CreateChatSchema extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        last_message TEXT,
        last_at INTEGER,
        unread INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await context.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        body TEXT NOT NULL,
        outgoing INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<void> down(VeloraMigrationContext context) async {
    await context.execute('DROP TABLE IF EXISTS messages');
    await context.execute('DROP TABLE IF EXISTS conversations');
  }
}
