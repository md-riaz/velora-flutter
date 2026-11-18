import 'native_notification_models.dart';

/// Provider-neutral interface for showing on-device notifications with action
/// buttons and activation tracking.
///
/// New code should use this instead of [LocalNotificationAdapter]. The old
/// adapter is kept for one deprecation cycle via [NativeNotificationsCompat].
abstract interface class VeloraNativeNotifications {
  /// Activations from notification taps and action buttons.
  ///
  /// Includes both cold-start (the app was launched by a notification tap) and
  /// live (the app was already running) activations, merged into one stream.
  Stream<VeloraNotificationActivation> get activations;

  /// One-time platform initialization. Must be called before [show].
  Future<void> initialize();

  /// Shows (or replaces) a notification.
  ///
  /// Showing a notification whose [VeloraNativeNotification.id] matches an
  /// already-visible one replaces it in place.
  Future<void> show(VeloraNativeNotification notification);

  /// Cancels a previously shown notification by its string ID.
  Future<void> cancel(String id);

  /// Cancels every notification this app has shown.
  Future<void> cancelAll();

  /// Releases resources. The instance must not be used after this.
  Future<void> dispose();
}
