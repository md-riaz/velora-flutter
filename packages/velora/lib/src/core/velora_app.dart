import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VeloraApp extends StatelessWidget {
  final String title;
  final String initialRoute;
  final List<GetPage<dynamic>> routes;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final Widget? home;

  const VeloraApp({
    required this.title,
    this.initialRoute = '/',
    this.routes = const [],
    this.theme,
    this.darkTheme,
    this.home,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: title,
      initialRoute: home == null ? initialRoute : null,
      getPages: routes,
      theme: theme,
      darkTheme: darkTheme,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
