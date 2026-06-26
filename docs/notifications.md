# 6 — Notifications

**What you'll do:** Scaffold a complete notification module with one command, wire FCM/APNs for remote push, and build an in-app notification center backed by your Laravel API.

---

## Scaffold the module

Run this from your app root to generate the complete notifications module:

```sh
dart run velora_cli make:notifications
```

This writes `lib/app/modules/notifications/` with:

- `NotificationService` — GetxService owning push token registration, unread count, and notification list
- `NotificationRepository` and `NotificationRemoteDataSource` — API layer
- `NotificationController`, pages, and widgets
- Noop/mock adapters so everything compiles and runs without Firebase credentials

## The notification stack

```text
Notification UI
  ↓
NotificationController
  ↓
NotificationService (GetxService)
  ↓
NotificationRepository
  ↓
NotificationRemoteDataSource
  ↓
Velora.api
  ↓
Laravel API
```

Laravel is the notification source of truth — FCM is transport only. The service owns `unreadCount`, the notification list, and push token registration. Never store any of these in a controller.

## Add push support

```sh
# Firebase Cloud Messaging (Android, iOS, Web)
dart run velora_cli install:push --fcm

# Local notifications only (no Firebase required)
dart run velora_cli install:push --local
```

`install:push --fcm` writes `web/firebase-messaging-sw.js` and `docs/reminders/` with platform-specific checklists for Android, iOS, Web, and Laravel.

## Platform checklist

=== "Android"
    - Add `android/app/google-services.json`
    - Apply the Google Services Gradle plugin
    - Request `POST_NOTIFICATIONS` permission on Android 13+
    - Set a default notification channel

=== "iOS"
    - Add `ios/Runner/GoogleService-Info.plist`
    - Enable the Push Notifications capability
    - Enable Background Modes → Remote notifications
    - Upload your APNs key to Firebase Console

=== "Web"
    - Configure `web/firebase-messaging-sw.js` with your Firebase project config
    - Add your VAPID key to Firebase Console

=== "Laravel"
    Expose these endpoints:

    ```
    GET    /notifications           paginated list
    POST   /notifications/{id}/read
    POST   /notifications/read-all
    POST   /device-tokens           register FCM token
    DELETE /device-tokens/{token}
    ```

    Payload fields: `type`, `title`, `body`, `route`, `data`, `read_at`, timestamps.

## Using `Velora.notify`

Once the generated service is bound, interact with it through the facade:

```dart
Velora.notify.unreadCount;           // Rx<int> — reactive badge count
Velora.notify.notifications;         // RxList<NotificationItem>
await Velora.notify.markRead(id);
await Velora.notify.markAllRead();
```

## Rules

- Never call Firebase Messaging or local notification plugins from views or controllers.
- Never store unread counts, notification lists, push tokens, or routing state in controllers.
- Keep the generated noop/mock adapter bound until real platform push is configured.

---

**Next:** [7 — Scaffold a Module →](scaffolding.md)
