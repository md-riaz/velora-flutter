import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

import 'app/data/chat_schema.dart';
import 'app/data/chat_tables.dart';
import 'app/data/conversation.dart';
import 'app/data/message.dart';
import 'app/offline/mock_chat_server_interceptor.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

const _uuid = Uuid();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final toggleSource = ToggleConnectivitySource();

  await Velora.boot(
    config: const VeloraConfig(
      appName: 'Velora Chat',
      // No real backend — MockChatServerInterceptor (added below) stands in
      // for one, so this URL is never actually dialed.
      apiBaseUrl: 'https://example.invalid',
      notifications: VeloraNotificationConfig(
        enabled: false,
        provider: PushProvider.none,
      ),
    ),
    plugins: [
      VeloraDbPlugin(
        databaseName: 'velora_chat.db',
        version: 1,
        migrations: [CreateChatSchema()],
      ),
      VeloraOfflinePlugin(source: toggleSource),
    ],
  );

  // Registered so the conversations page can reach this exact instance to
  // flip simulated connectivity from its online/offline `Switch`.
  Get.put<ToggleConnectivitySource>(toggleSource, permanent: true);

  // Stands in for a real backend — see its dartdoc for exactly what it does
  // (and does not do).
  Velora.api.addInterceptor(MockChatServerInterceptor());

  await _seedDemoDataIfEmpty();

  runApp(const VeloraChatApp());
}

/// Seeds a couple of conversations with a short back-and-forth so the app
/// isn't empty on first run. Only runs once — skipped on every later launch
/// since `velora_chat.db` persists across restarts.
Future<void> _seedDemoDataIfEmpty() async {
  final conversations = conversationsTable();
  final messages = messagesTable();
  if (await conversations.count() > 0) return;

  final now = DateTime.now();

  Future<void> seedConversation({
    required String title,
    required List<(String body, bool outgoing, int minutesAgo)> thread,
  }) async {
    final conversationId = _uuid.v4();
    DateTime? lastAt;
    String? lastMessage;
    for (final (body, outgoing, minutesAgo) in thread) {
      final createdAt = now.subtract(Duration(minutes: minutesAgo));
      await messages.insert(
        Message(
          id: _uuid.v4(),
          conversationId: conversationId,
          body: body,
          outgoing: outgoing,
          status: 'sent',
          createdAt: createdAt,
        ).toMap(),
      );
      lastAt = createdAt;
      lastMessage = body;
    }
    await conversations.insert(
      Conversation(
        id: conversationId,
        title: title,
        lastMessage: lastMessage,
        lastAt: lastAt,
      ).toMap(),
    );
  }

  await seedConversation(
    title: 'Amina',
    thread: [
      ('Hey! Are we still on for lunch tomorrow?', false, 60),
      ('Yes, 1pm works great 👍', true, 58),
      ('Perfect, see you then.', false, 57),
    ],
  );

  await seedConversation(
    title: 'Family Group',
    thread: [
      ("Dad: Don't forget to call grandma this weekend.", false, 200),
      ('On it!', true, 195),
    ],
  );

  await seedConversation(
    title: 'Sam (Work)',
    thread: [
      ('Can you review the PR when you get a chance?', false, 20),
    ],
  );
}

class VeloraChatApp extends StatelessWidget {
  const VeloraChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Velora Chat',
      initialRoute: AppRoutes.conversations,
      routes: AppPages.routes,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF25D366),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF25D366),
        brightness: Brightness.dark,
      ),
    );
  }
}
