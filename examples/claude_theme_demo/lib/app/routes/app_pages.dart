import 'package:get/get.dart';

import '../modules/account/account_controller.dart';
import '../modules/account/account_page.dart';
import '../modules/chat/chat_controller.dart';
import '../modules/chat/chat_page.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_page.dart';
import '../modules/settings/settings_controller.dart';
import '../modules/settings/settings_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ChatController())),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SettingsController())),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AccountController())),
    ),
  ];
}
