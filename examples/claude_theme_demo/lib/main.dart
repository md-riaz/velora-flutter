import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'app/modules/settings/settings_controller.dart';
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

  // Register feature flags once at startup so FeatureService state persists
  // across SettingsController lifecycles.
  _registerAppFeatures();

  runApp(const ClaudeApp());
}

void _registerAppFeatures() {
  for (final f in SettingsController.demoFeatures) {
    Velora.feature.register(VeloraFeature(id: f.id, name: f.label));
  }
}

class ClaudeApp extends StatelessWidget {
  const ClaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VeloraApp(
      title: 'Claude',
      initialRoute: Velora.auth.check ? AppRoutes.home : AppRoutes.login,
      routes: AppPages.routes,
      theme: ClaudeTheme.light(),
      darkTheme: ClaudeTheme.dark(),
      // VeloraApp resolves the persisted ThemeMode from ThemeService
      // on first build, so toggling light/dark mode survives app restarts.
    );
  }
}
