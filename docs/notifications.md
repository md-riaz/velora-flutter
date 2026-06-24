# Notifications

Velora notifications use one service-owned flow for remote push, local notifications, and in-app notification center state.

```text
Notification UI
  ↓
NotificationController
  ↓
NotificationService / GetxService
  ↓
NotificationRepository
  ↓
NotificationRemoteDataSource
  ↓
Velora.api
  ↓
Laravel API
```

Laravel is the notification source of truth. FCM is transport only for Android, iOS, and Web push. Local notifications handle foreground or app-triggered display. Generated code includes noop/mock adapters so UI and API contracts can be developed without Firebase credentials or device push setup.

## CLI

```sh
dart run velora_cli make:notifications
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
```

`make:notifications` writes `lib/app/modules/notifications` with service, repository, data source, adapters, entities, controller, pages, and widgets.

`install:push --fcm` writes `web/firebase-messaging-sw.js` with placeholder Firebase config plus reminder docs under `docs/reminders` for Android, iOS, Web, and Laravel.

`install:push --local` writes local notification adapter placeholders and reminder docs. It does not require Firebase files or server credentials.

## Platform setup reminders

Android needs `android/app/google-services.json`, Gradle Google Services setup, Android 13 `POST_NOTIFICATIONS`, and a default notification channel when real push/local display is enabled.

iOS needs `ios/Runner/GoogleService-Info.plist`, Push Notifications capability, Background Modes -> Remote notifications, APNs key uploaded to Firebase Console, and a permission prompt.

Web needs `web/firebase-messaging-sw.js`, Firebase config in web bootstrap as needed, and a VAPID key.

Laravel needs endpoints for notifications, mark-as-read, mark-all-as-read, and device token register/unregister. Backend payloads should include `type`, `feature`, `permission`, `title`, `body`, `route`, `data`, `read_at`, and timestamps.

## Rules

Do not store unread counts, lists, push tokens, permission state, or routing state in controllers. Do not call Firebase Messaging or local notification plugins from views/controllers. Use `Velora.notify` when bound, or inject the generated `NotificationService` from the notification binding.
