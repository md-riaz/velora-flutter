import 'package:velora/velora.dart';

import '../modules/chat/chat_controller.dart';
import '../modules/chat/chat_page.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
      // In a real app, guard protected routes like so:
      //   middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ChatController())),
      // middlewares: Velora.authOnly,
    ),
  ];
}
