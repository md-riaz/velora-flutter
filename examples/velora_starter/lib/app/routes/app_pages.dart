import 'package:flutter/material.dart';

import 'package:velora/velora.dart';

import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/logout_state.dart';
import '../modules/dashboard/dashboard_page.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/presentation/views/notification_details_page.dart';
import '../modules/notifications/presentation/views/notifications_index_page.dart';
import '../modules/splash_page.dart';
import '../modules/users/users_binding.dart';
import '../modules/users/views/user_create_page.dart';
import '../modules/users/views/user_edit_page.dart';
import '../modules/users/views/user_show_page.dart';
import '../modules/users/views/users_index_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    _protected(name: AppRoutes.dashboard, page: () => const DashboardPage()),
    _protected(
      name: AppRoutes.users,
      page: () => const UsersIndexPage(),
      binding: UsersBinding(),
    ),
    _protected(name: AppRoutes.usersCreate, page: () => const UserCreatePage()),
    _protected(name: AppRoutes.usersEdit, page: () => const UserEditPage()),
    _protected(name: AppRoutes.usersShow, page: () => const UserShowPage()),
    _protected(
      name: AppRoutes.notifications,
      page: () => const NotificationsIndexPage(),
      binding: NotificationsBinding(),
    ),
    _protected(
      name: AppRoutes.notificationDetail,
      page: () => const NotificationDetailsPage(),
      binding: NotificationsBinding(),
    ),
  ];

  static GetPage<dynamic> _protected({
    required String name,
    required GetPageBuilder page,
    Bindings? binding,
  }) {
    return GetPage<dynamic>(
      name: name,
      page: page,
      binding: binding,
      middlewares: [AuthMiddleware()],
    );
  }
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (isVeloraLogoutRunning()) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return Velora.auth.check
        ? null
        : const RouteSettings(name: AppRoutes.login);
  }
}
