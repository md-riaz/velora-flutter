import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

class AppThemeMode {
  static final mode = ThemeMode.system.obs;
  static void init() {
    final saved = Velora.storage.get<String>('velora.theme.mode');
    mode.value = ThemeMode.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static void setMode(ThemeMode value) {
    mode.value = value;
    Velora.storage.set('velora.theme.mode', value.name);
  }

  static void toggle() =>
      setMode(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
