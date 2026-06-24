import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'app/modules/auth/auth_binding.dart';
import 'app/modules/notifications/notifications_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'resources/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Velora.boot(
    config: const VeloraConfig(
      appName: 'Velora Starter',
      apiBaseUrl: 'https://api.example.com/api',
      notifications: VeloraNotificationConfig(provider: PushProvider.none),
    ),
  );
  AuthBinding().dependencies();
  NotificationsBinding().dependencies();
  runApp(const StarterApp());
}

class StarterApp extends StatelessWidget {
  const StarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Velora Starter',
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
