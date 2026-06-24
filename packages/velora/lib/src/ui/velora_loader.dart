import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VeloraLoader extends GetxService {
  bool _showing = false;

  void show() {
    if (_showing) return;
    _showing = true;
    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  void hide() {
    if (!_showing) return;
    _showing = false;
    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }
  }

  Future<T> run<T>(Future<T> Function() task) async {
    show();
    try {
      return await task();
    } finally {
      hide();
    }
  }
}
