import 'package:velora/velora.dart';
import 'package:velora_offline/velora_offline.dart';

import '../../data/chat_tables.dart';
import 'conversations_controller.dart';

/// Builds a [ConversationsController] with its dependencies constructed
/// explicitly (constructor DI), rather than the controller reaching into
/// `Get.find`/service locators itself.
class ConversationsModule {
  static ConversationsController controller() {
    return ConversationsController(
      table: conversationsTable(),
      toggleSource: Get.find<ToggleConnectivitySource>(),
    );
  }
}
