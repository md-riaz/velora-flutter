import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

const _kFeatureVoice = 'chat.voice';
const _kFeatureCanvas = 'chat.canvas';
const _kFeatureCodeInterpreter = 'advanced.code_interpreter';
const _kFeatureArtifacts = 'chat.artifacts';

/// Demonstrates [ThemeService] and [FeatureService] patterns.
///
/// On [onInit] the demo features are registered with [FeatureService] so the
/// settings page can toggle them with [FeatureService.enable] /
/// [FeatureService.disable].
class SettingsController extends VeloraController {
  @override
  void onInit() {
    super.onInit();
    _registerDemoFeatures();
  }

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
    (id: _kFeatureVoice, label: 'Voice input', description: 'Speak instead of type'),
    (id: _kFeatureCanvas, label: 'Canvas mode', description: 'Side-by-side editor view'),
    (id: _kFeatureCodeInterpreter, label: 'Code interpreter', description: 'Run code in chat'),
    (id: _kFeatureArtifacts, label: 'Artifacts', description: 'Render live previews'),
  ];

  bool isEnabled(String featureId) => Velora.feature.enabled(featureId);

  void toggle(String featureId) {
    if (Velora.feature.enabled(featureId)) {
      Velora.feature.disable(featureId);
    } else {
      Velora.feature.enable(featureId);
    }
  }

  void _registerDemoFeatures() {
    for (final f in demoFeatures) {
      Velora.feature.register(VeloraFeature(id: f.id, name: f.label));
    }
  }
}
