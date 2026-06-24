import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

class AppTheme {
  static ThemeData light() => VeloraTheme.light(seedColor: Colors.indigo);
  static ThemeData dark() => VeloraTheme.dark(seedColor: Colors.indigo);
}
