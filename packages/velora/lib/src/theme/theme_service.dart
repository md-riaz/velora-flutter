import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeService extends GetxService {
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  ThemeMode get current => mode.value;

  void useSystem() => setMode(ThemeMode.system);
  void useLight() => setMode(ThemeMode.light);
  void useDark() => setMode(ThemeMode.dark);

  void setMode(ThemeMode value) {
    mode.value = value;
    Get.changeThemeMode(value);
  }
}

class VeloraTheme {
  static ThemeData light({Color seedColor = Colors.indigo}) {
    return _theme(Brightness.light, seedColor);
  }

  static ThemeData dark({Color seedColor = Colors.indigo}) {
    return _theme(Brightness.dark, seedColor);
  }

  static ThemeData _theme(Brightness brightness, Color seedColor) {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(8)),
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    );
  }
}
