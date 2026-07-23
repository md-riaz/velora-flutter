import 'dart:async';

import 'package:get/get.dart';

import '../core/velora_facade.dart';

abstract class VeloraController extends GetxController {
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

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

  /// Subscribes to [source], routing each event to [onData], and cancels the
  /// subscription automatically when this controller is disposed ([onClose]).
  ///
  /// Use this to bind a reactive source — e.g. a `velora_db` `watchAll()` /
  /// `watchQuery(...)` stream — into controller state without hand-managing a
  /// [StreamSubscription]:
  ///
  /// ```dart
  /// final messages = <Message>[].obs;
  ///
  /// @override
  /// void onInit() {
  ///   super.onInit();
  ///   listenStream(repo.watchAll(), messages.assignAll);
  /// }
  /// ```
  ///
  /// Returns the [StreamSubscription] so a caller can cancel it early if it
  /// needs to; that is optional — [onClose] cancels any still-active ones.
  StreamSubscription<T> listenStream<T>(
    Stream<T> source,
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    _subscriptions.add(subscription);
    return subscription;
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }
}
