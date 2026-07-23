import 'package:velora/velora.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/chat_tables.dart';
import '../../data/conversation.dart';
import '../../data/message.dart';
import 'chat_controller.dart';

/// Builds a [ChatController] with its dependencies constructed explicitly
/// (constructor DI): the conversation id/title come from the route
/// parameters/arguments GetX resolved for this page, and the offline-first
/// message repository is built here, once, per navigation to this route.
class ChatModule {
  static ChatController controller() {
    final id = Get.parameters['id'] ?? '';
    final args = Get.arguments;
    final title = args is Conversation ? args.title : 'Chat';

    return ChatController(
      conversationId: id,
      conversationTitle: title,
      messagesRepository: VeloraOffline.offlineFirst<Message, String>(
        table: messagesTable(),
        endpoint: 'messages',
      ),
      conversationsTable: conversationsTable(),
      toggleSource: Get.find<ToggleConnectivitySource>(),
    );
  }
}
