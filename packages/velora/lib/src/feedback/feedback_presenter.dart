abstract interface class FeedbackPresenter {
  void success(String message);
  void error(String message);
  Future<bool> confirm(ConfirmationRequest request);
}

final class ConfirmationRequest {
  const ConfirmationRequest({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
}

class NoopFeedbackPresenter implements FeedbackPresenter {
  const NoopFeedbackPresenter();

  @override
  void success(String message) {}

  @override
  void error(String message) {}

  @override
  Future<bool> confirm(ConfirmationRequest request) => throw StateError(
    'Register a FeedbackPresenter with Velora.boot(feedback: ...) to confirm.',
  );
}
