import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../shared/feature_ids.dart';

/// Demonstrates [ThemeService] and [FeatureService] patterns.
///
/// Demo features are registered once at app startup (see [main]) so they
/// persist across [SettingsController] lifecycles.  The controller toggles
/// them with [FeatureService.enable] / [FeatureService.disable].
class SettingsController extends VeloraController {
  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  ThemeMode get currentTheme => Velora.theme.current;

  void setTheme(ThemeMode mode) {
    Velora.theme.setMode(mode);
  }

  // ---------------------------------------------------------------------------
  // Feature flags
  // ---------------------------------------------------------------------------

  static const demoFeatures = [
    (id: AppFeatures.voice, label: 'Voice input', description: 'Speak instead of type'),
    (id: AppFeatures.canvas, label: 'Canvas mode', description: 'Side-by-side editor view'),
    (id: AppFeatures.codeInterpreter, label: 'Code interpreter', description: 'Run code in chat'),
    (id: AppFeatures.artifacts, label: 'Artifacts', description: 'Render live previews'),
  ];

  bool isEnabled(String featureId) => Velora.feature.enabled(featureId);

  void toggle(String featureId) {
    if (Velora.feature.enabled(featureId)) {
      Velora.feature.disable(featureId);
    } else {
      Velora.feature.enable(featureId);
    }
  }
}
