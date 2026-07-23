import 'package:velora_db/velora_db.dart';

import 'conversation.dart';
import 'message.dart';

/// Binds a [VeloraTable] to the `conversations` table. Kept in one place so
/// every caller (boot seeding, the mock server, the conversations module)
/// binds the exact same `fromMap`/`toMap` pair.
VeloraTable<Conversation, String> conversationsTable() {
  return VeloraDb.table<Conversation, String>(
    table: 'conversations',
    fromMap: Conversation.fromMap,
    toMap: (conversation) => conversation.toMap(),
  );
}

/// Binds a [VeloraTable] to the `messages` table. See [conversationsTable].
VeloraTable<Message, String> messagesTable() {
  return VeloraDb.table<Message, String>(
    table: 'messages',
    fromMap: Message.fromMap,
    toMap: (message) => message.toMap(),
  );
}
