import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'resources/theme/claude_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Velora.boot(
    config: const VeloraConfig(
      appName: 'Claude Demo',
      // No real API needed — all data is mocked in controllers.
      apiBaseUrl: 'https://api.anthropic.com',
      notifications: VeloraNotificationConfig(
        enabled: false,
        provider: PushProvider.none,
      ),
    ),
  );

  runApp(const ClaudeApp());
}

class ClaudeApp extends StatelessWidget {
  const ClaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Claude',
      initialRoute: AppRoutes.home,
      routes: AppPages.routes,
      theme: ClaudeTheme.light(),
      darkTheme: ClaudeTheme.dark(),
      // VeloraApp resolves the persisted ThemeMode from ThemeService
      // on first build, so toggling light/dark mode survives app restarts.
    );
  }
}
