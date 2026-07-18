import 'package:get/get.dart';

import '../core/velora_facade.dart';

abstract class VeloraController extends GetxController {
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  /// Runs [task] with loading/error bookkeeping.
  ///
  /// On failure the exception message is stored in [error] and, by default, a
  /// toast is shown. Presentation is opt-out so a controller can orchestrate
  /// async work without forcing UI:
  ///
  /// - [showErrorToast] (default `true`) — set `false` to handle the error via
  ///   the reactive [error] field instead of a toast (e.g. inline field errors).
  /// - [rethrowError] (default `false`) — set `true` to rethrow after recording
  ///   the error, so callers can branch on failure rather than a `null` result.
  Future<T?> run<T>(
    Future<T> Function() task, {
    bool showLoader = false,
    String? successMessage,
    String? errorMessage,
    bool showErrorToast = true,
    bool rethrowError = false,
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
      if (showErrorToast) Velora.toast.error(message);
      if (rethrowError) rethrow;
      return null;
    } finally {
      loading.value = false;
      if (showLoader) Velora.loader.hide();
    }
  }

  void clearError() => error.value = '';
}
