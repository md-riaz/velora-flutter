import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VeloraToast extends GetxService {
  void success(String message) => _show('Success', message, Colors.green);
  void error(String message) => _show('Error', message, Colors.red);
  void info(String message) => _show('Info', message, Colors.blue);
  void warning(String message) => _show('Warning', message, Colors.orange);

  void _show(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
