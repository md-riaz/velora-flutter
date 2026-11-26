import 'material_feedback_presenter.dart';
import 'app/shared/app_theme_mode.dart';

import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'app/modules/settings/settings_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'resources/theme/claude_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Velora.boot(
    feedback: const MaterialFeedbackPresenter(),
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

  AppThemeMode.init();

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
    return Obx(
      () => GetMaterialApp(
        title: 'Claude',
        initialRoute: Velora.auth.check ? AppRoutes.home : AppRoutes.login,
        getPages: AppPages.routes,
        theme: ClaudeTheme.light(),
        darkTheme: ClaudeTheme.dark(),
        themeMode: AppThemeMode.mode.value,
      ),
    );
  }
}
