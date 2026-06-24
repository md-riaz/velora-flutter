import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/velora_storage_service.dart';

class ThemeService extends GetxService {
  static const _modeKey = 'velora.theme.mode';

  final VeloraStorageService? _storage;

  ThemeService({VeloraStorageService? storage}) : _storage = storage;

  final Rx<ThemeMode> mode = ThemeMode.system.obs;
  ThemeMode get current => mode.value;

  Future<ThemeService> init() async {
    final saved = _storage?.get<String>(_modeKey);
    if (saved != null) {
      mode.value = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
    return this;
  }

  void useSystem() => setMode(ThemeMode.system);
  void useLight() => setMode(ThemeMode.light);
  void useDark() => setMode(ThemeMode.dark);

  void toggle() {
    setMode(current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setMode(ThemeMode value) {
    mode.value = value;
    Get.changeThemeMode(value);
    _storage?.set(_modeKey, value.name);
  }
}

class VeloraTheme {
  static ThemeData light({Color seedColor = Colors.indigo}) {
    return _theme(Brightness.light, seedColor);
  }

  static ThemeData dark({Color seedColor = Colors.indigo}) {
    return _theme(Brightness.dark, seedColor);
  }

  /// Build a [ThemeData] from a fully-specified [ColorScheme], allowing
  /// complete control over colors while still applying Velora's component defaults.
  ///
  /// Use this when [ColorScheme.fromSeed] doesn't give you the exact palette
  /// you need (e.g. brand-specific color systems like Claude's warm copper tones).
  static ThemeData fromScheme({
    required ColorScheme colorScheme,
    TextTheme? textTheme,
    Color? scaffoldBackgroundColor,
    double inputBorderRadius = 8,
    double cardBorderRadius = 12,
    double buttonBorderRadius = 8,
    List<ThemeExtension<dynamic>> extensions = const [],
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      extensions: extensions,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(backgroundColor: colorScheme.surface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
      ),
    );
  }

  static ThemeData _theme(Brightness brightness, Color seedColor) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(8)),
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
