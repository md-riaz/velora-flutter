import 'package:velora/velora.dart';

import '../modules/account/account_controller.dart';
import '../modules/account/account_page.dart';
import '../modules/account/edit_profile_controller.dart';
import '../modules/account/edit_profile_page.dart';
import '../modules/auth/login_controller.dart';
import '../modules/auth/login_page.dart';
import '../modules/chat/chat_controller.dart';
import '../modules/chat/chat_page.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_page.dart';
import '../modules/notifications/notifications_controller.dart';
import '../modules/notifications/notifications_page.dart';
import '../modules/settings/settings_controller.dart';
import '../modules/settings/settings_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => LoginController(), fenix: true)),
      middlewares: Velora.guestOnly(authenticatedRoute: AppRoutes.home),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController(), fenix: true)),
      middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ChatController(), fenix: true)),
      middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SettingsController(), fenix: true)),
      middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AccountController(), fenix: true)),
      middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => NotificationsController(), fenix: true),
      ),
      middlewares: Velora.authOnly,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => EditProfileController(), fenix: true),
      ),
      middlewares: Velora.authOnly,
    ),
  ];
}
