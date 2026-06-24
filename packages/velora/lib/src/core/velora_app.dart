import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VeloraApp extends StatelessWidget {
  final String title;
  final String initialRoute;
  final List<GetPage<dynamic>> routes;
  final ThemeData? theme;
  final ThemeData? darkTheme;

  /// Override the initial [ThemeMode]. When null, falls back to
  /// [ThemeService.current] (which may be a previously-persisted value)
  /// or [ThemeMode.system] if the service is not yet available.
  final ThemeMode? themeMode;
  final Widget? home;

  const VeloraApp({
    required this.title,
    this.initialRoute = '/',
    this.routes = const [],
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.home,
    super.key,
  });

  ThemeMode _resolveThemeMode() {
    if (themeMode != null) return themeMode!;
    try {
      return Get.find<ThemeService>().current;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: title,
      initialRoute: home == null ? initialRoute : null,
      getPages: routes,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: _resolveThemeMode(),
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
