# Notification Architecture

Velora notifications use:

- NotificationService as the single source of truth.
- NotificationRepository for Laravel API access.
- FcmPushAdapter for remote push when Firebase is configured.
- LocalNotificationAdapter for local display.
- NoopPushAdapter for mock/noop mode during local development.
- Feature-aware routing and permission-aware display.

Rules:

- Do not store notification state in controllers.
- Do not directly use FirebaseMessaging inside views/controllers.
- Do not directly use FlutterLocalNotificationsPlugin inside views/controllers.
- Use Velora.notify when runtime support is bound, otherwise inject NotificationService from the generated binding.
