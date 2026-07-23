import 'package:velora/velora.dart';

import '../modules/chat/chat_module.dart';
import '../modules/chat/chat_page.dart';
import '../modules/conversations/conversations_module.dart';
import '../modules/conversations/conversations_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.conversations,
      page: () => const ConversationsPage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(ConversationsModule.controller, fenix: true),
      ),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(ChatModule.controller, fenix: true),
      ),
    ),
  ];
}
