import 'package:get/get.dart';

import '../core/velora_facade.dart';

abstract class VeloraController extends GetxController {
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  Future<T?> run<T>(
    Future<T> Function() task, {
    bool showLoader = false,
    String? successMessage,
    String? errorMessage,
  }) async {
    clearError();
    try {
      loading.value = true;
      if (showLoader) Velora.loader.show();
      final result = await task();
      if (successMessage != null) Velora.toast.success(successMessage);
      return result;
    } catch (exception) {
      final message = errorMessage ?? exception.toString();
      error.value = message;
      Velora.toast.error(message);
      return null;
    } finally {
      loading.value = false;
      if (showLoader) Velora.loader.hide();
    }
  }

  void clearError() => error.value = '';
}
