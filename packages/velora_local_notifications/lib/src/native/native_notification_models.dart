/// Provider-neutral notification models for [VeloraNativeNotifications].
///
/// No flutter_local_notifications or Windows SDK type enters these models.
library;

/// A notification to show.
class VeloraNativeNotification {
  const VeloraNativeNotification({
    required this.id,
    required this.title,
    this.body,
    this.payload = const {},
    this.actions = const [],
    this.silent = false,
  });

  /// Stable string ID. Showing the same [id] replaces the previous one.
  final String id;

  final String title;

  final String? body;

  /// Opaque data returned in [VeloraNotificationActivation.payload].
  final Map<String, dynamic> payload;

  /// Action buttons. Platform support varies; unsupported buttons are silently
  /// dropped.
  final List<VeloraNativeAction> actions;

  /// When `true`, the notification plays no sound and does not vibrate.
  final bool silent;
}

/// An action button on a notification.
class VeloraNativeAction {
  const VeloraNativeAction({
    required this.id,
    required this.label,
    this.textInputPlaceholder,
  });

  /// Returned in [VeloraNotificationActivation.actionId] when the user taps
  /// this action.
  final String id;

  /// The button label.
  final String label;

  /// When non-null, a text field is shown alongside this button. The user's
  /// input is returned in [VeloraNotificationActivation.input].
  final String? textInputPlaceholder;
}

/// Delivered when the user taps a notification or one of its actions.
class VeloraNotificationActivation {
  const VeloraNotificationActivation({
    required this.id,
    this.actionId,
    this.input,
    this.payload = const {},
    this.data = const {},
  });

  /// The [VeloraNativeNotification.id] (string, not the hashed int).
  final String id;

  /// Non-null when the user tapped an action button.
  final String? actionId;

  /// The text the user typed, when the action had a text input.
  final String? input;

  /// The [VeloraNativeNotification.payload] that was stored with the
  /// notification.
  final Map<String, dynamic> payload;

  /// Platform-specific extra data (e.g. Windows input values keyed by input
  /// ID).
  final Map<String, dynamic> data;
}
