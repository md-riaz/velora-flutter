Velora Notifications — Full Spec & Implementation Plan

This module should be named:

VeloraNotify

Developer-facing facade:

Velora.notify

Example usage:

await Velora.notify.initForUser();

Velora.notify.unreadCount;

await Velora.notify.showLocal(
  title: 'Saved',
  body: 'User created successfully',
);

await Velora.notify.markAsRead(notificationId);

Core idea:

> Laravel remains the notification source of truth.
FCM handles remote push delivery for Android, iOS, and Web.
Flutter local notifications handles local/foreground display.
GetxService owns notification state.
Repositories only handle data access.




---

1. Notification Types

Velora should support three notification types.

Type	Meaning	Example

Remote Push	Sent from Laravel through FCM	“New order received”
Local Notification	Triggered by the app itself	“Upload completed”
In-App Notification	Stored in Laravel and shown in notification center	Bell icon list


All three should flow through one service:

NotificationService extends GetxService


---

2. High-Level Architecture

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

For remote push:

Laravel Event
  ↓
Laravel Notification / Job
  ↓
FCM
  ↓
Flutter App
  ↓
FcmPushAdapter
  ↓
NotificationService
  ↓
Local display / route action / in-app sync

For local notification:

App Action
  ↓
Velora.notify.showLocal()
  ↓
NotificationService
  ↓
LocalNotificationAdapter
  ↓
Device notification tray


---

3. Official Velora Rule

Notifications must follow this rule:

NotificationService is the single source of truth.

Controllers must not own unread count, notification list, push token,
permission status, or notification routing state.

Good:

Velora.notify.unreadCount;
Velora.notify.notifications;
Velora.notify.permissionGranted;

Bad:

DashboardController.unreadCount;
NavbarController.notificationCount;
NotificationsController.notifications;


---

4. Package Dependencies

For MVP, include:

dependencies:
  firebase_core: latest
  firebase_messaging: latest
  flutter_local_notifications: latest
  get: latest
  dio: latest

Do not use:

Firebase Auth
Firestore
Realtime Database
Supabase

Firebase is only used as the push transport layer.


---

5. Folder Structure

Generated notification module:

lib/app/modules/notifications/
  notifications_feature.dart
  notifications_binding.dart
  notifications_routes.dart

  presentation/
    notifications_controller.dart
    views/
      notifications_index_page.dart
      notification_details_page.dart
    widgets/
      notification_tile.dart
      notification_badge.dart

  application/
    notification_service.dart

  domain/
    repositories/
      notification_repository.dart
    entities/
      app_notification.dart
      push_message.dart
      device_token.dart

  data/
    repositories/
      notification_repository_impl.dart
    datasources/
      notification_remote_datasource.dart
    adapters/
      fcm_push_adapter.dart
      local_notification_adapter.dart
      noop_push_adapter.dart
    models/
      app_notification_model.dart
      device_token_model.dart

Core package files:

packages/velora/lib/src/notifications/
  velora_notify.dart
  notification_config.dart
  notification_service.dart
  notification_repository.dart
  notification_event.dart
  notification_payload.dart
  adapters/
    push_adapter.dart
    local_notification_adapter.dart
    fcm_push_adapter.dart


---

6. Public Facade API

Expose notifications through:

Velora.notify

Facade class:

class Velora {
  static NotificationService get notify => Get.find<NotificationService>();
}

Developer API:

await Velora.notify.initForUser();

await Velora.notify.requestPermission();

await Velora.notify.registerDeviceToken();

await Velora.notify.fetch();

await Velora.notify.markAsRead(id);

await Velora.notify.markAllAsRead();

await Velora.notify.showLocal(
  title: 'Saved',
  body: 'User created successfully',
);

await Velora.notify.scheduleLocal(
  id: 'reminder_1',
  title: 'Reminder',
  body: 'Submit your report',
  dateTime: DateTime.now().add(Duration(hours: 1)),
);

await Velora.notify.cancelLocal('reminder_1');

await Velora.notify.cancelAllLocal();

await Velora.notify.handleTap(notification);

Reactive state:

Velora.notify.notifications;
Velora.notify.unreadCount;
Velora.notify.permissionGranted;
Velora.notify.pushToken;
Velora.notify.initialized;


---

7. Notification Config

Add this to VeloraConfig.

class VeloraNotificationConfig {
  final bool enabled;

  final PushProvider provider;

  final bool requestPermissionAfterLogin;

  final bool showForegroundRemoteAsLocal;

  final bool syncInAppNotificationsAfterPush;

  final String deviceRegisterEndpoint;

  final String deviceUnregisterEndpoint;

  final String notificationsEndpoint;

  final String markAsReadEndpoint;

  final String markAllAsReadEndpoint;

  const VeloraNotificationConfig({
    this.enabled = true,
    this.provider = PushProvider.fcm,
    this.requestPermissionAfterLogin = true,
    this.showForegroundRemoteAsLocal = true,
    this.syncInAppNotificationsAfterPush = true,
    this.deviceRegisterEndpoint = '/devices',
    this.deviceUnregisterEndpoint = '/devices',
    this.notificationsEndpoint = '/notifications',
    this.markAsReadEndpoint = '/notifications/{id}/read',
    this.markAllAsReadEndpoint = '/notifications/read-all',
  });
}

enum PushProvider {
  none,
  fcm,
}

Usage:

await Velora.boot(
  config: VeloraConfig(
    apiBaseUrl: 'https://example.com/api',
    notifications: VeloraNotificationConfig(
      enabled: true,
      provider: PushProvider.fcm,
      requestPermissionAfterLogin: true,
      showForegroundRemoteAsLocal: true,
    ),
  ),
);


---

8. Core Service: NotificationService

This is the heart of the module.

class NotificationService extends GetxService {
  final NotificationRepository repository;
  final PushAdapter pushAdapter;
  final LocalNotificationAdapter localAdapter;

  NotificationService({
    required this.repository,
    required this.pushAdapter,
    required this.localAdapter,
  });

  final notifications = <AppNotification>[].obs;

  final unreadCount = 0.obs;

  final permissionGranted = false.obs;

  final initialized = false.obs;

  final pushToken = RxnString();

  Future<void> initForUser() async {
    if (initialized.value) return;

    await localAdapter.init();
    await pushAdapter.init();

    permissionGranted.value = await pushAdapter.requestPermission();

    if (permissionGranted.value) {
      await registerDeviceToken();
    }

    _listenToForegroundMessages();
    _listenToNotificationOpenedApp();

    await fetch();

    initialized.value = true;
  }

  Future<void> registerDeviceToken() async {
    final token = await pushAdapter.getToken();

    if (token == null) return;

    pushToken.value = token;

    await repository.registerDeviceToken(
      token: token,
      provider: pushAdapter.provider,
      platform: VeloraPlatform.current,
    );
  }

  Future<void> fetch() async {
    final result = await repository.index();

    notifications.assignAll(result);

    _recalculateUnread();
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);

    final index = notifications.indexWhere((item) => item.id == id);

    if (index != -1) {
      notifications[index] = notifications[index].copyWith(
        readAt: DateTime.now(),
      );
    }

    _recalculateUnread();
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();

    notifications.assignAll(
      notifications.map((item) {
        return item.copyWith(readAt: DateTime.now());
      }).toList(),
    );

    _recalculateUnread();
  }

  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    await localAdapter.show(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> scheduleLocal({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) async {
    await localAdapter.schedule(
      id: id,
      title: title,
      body: body,
      dateTime: dateTime,
      payload: payload,
    );
  }

  Future<void> handleTap(AppNotification notification) async {
    final feature = notification.feature;
    final permission = notification.permission;
    final route = notification.route;

    if (feature != null && !Velora.feature.enabled(feature)) {
      Velora.nav.to('/403');
      return;
    }

    if (permission != null && !Velora.permission.can(permission)) {
      Velora.nav.to('/403');
      return;
    }

    await markAsRead(notification.id);

    if (route != null && route.isNotEmpty) {
      Velora.nav.to(route);
    }
  }

  Future<void> disposeForUser() async {
    final token = pushToken.value;

    if (token != null) {
      await repository.unregisterDeviceToken(token: token);
    }

    await pushAdapter.dispose();

    notifications.clear();
    unreadCount.value = 0;
    permissionGranted.value = false;
    initialized.value = false;
    pushToken.value = null;
  }

  void _listenToForegroundMessages() {
    pushAdapter.onMessage.listen((message) async {
      final notification = AppNotification.fromPushMessage(message);

      if (!_canDisplay(notification)) return;

      if (Velora.config.notifications.showForegroundRemoteAsLocal) {
        await showLocal(
          title: notification.title,
          body: notification.body,
          payload: notification.data,
        );
      }

      if (Velora.config.notifications.syncInAppNotificationsAfterPush) {
        await fetch();
      }
    });
  }

  void _listenToNotificationOpenedApp() {
    pushAdapter.onMessageOpenedApp.listen((message) async {
      final notification = AppNotification.fromPushMessage(message);
      await handleTap(notification);
    });
  }

  bool _canDisplay(AppNotification notification) {
    if (notification.feature != null &&
        !Velora.feature.enabled(notification.feature!)) {
      return false;
    }

    if (notification.permission != null &&
        !Velora.permission.can(notification.permission!)) {
      return false;
    }

    return true;
  }

  void _recalculateUnread() {
    unreadCount.value = notifications
        .where((item) => item.readAt == null)
        .length;
  }
}


---

9. Repository Contract

abstract class NotificationRepository {
  Future<List<AppNotification>> index();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  });

  Future<void> unregisterDeviceToken({
    required String token,
  });
}

Implementation:

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remote;

  NotificationRepositoryImpl(this.remote);

  @override
  Future<List<AppNotification>> index() {
    return remote.index();
  }

  @override
  Future<void> markAsRead(String id) {
    return remote.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return remote.markAllAsRead();
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  }) {
    return remote.registerDeviceToken(
      token: token,
      provider: provider,
      platform: platform,
    );
  }

  @override
  Future<void> unregisterDeviceToken({
    required String token,
  }) {
    return remote.unregisterDeviceToken(token: token);
  }
}


---

10. Remote Data Source

class NotificationRemoteDataSource {
  Future<List<AppNotification>> index() async {
    final response = await Velora.api.get('/notifications');

    final items = response.data['data'] as List;

    return items
        .map((item) => AppNotification.fromJson(item))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await Velora.api.post('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await Velora.api.post('/notifications/read-all');
  }

  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  }) async {
    await Velora.api.post(
      '/devices',
      data: {
        'token': token,
        'provider': provider,
        'platform': platform,
        'device_name': VeloraDevice.name,
        'app_version': VeloraAppInfo.version,
      },
    );
  }

  Future<void> unregisterDeviceToken({
    required String token,
  }) async {
    await Velora.api.delete(
      '/devices',
      data: {
        'token': token,
      },
    );
  }
}


---

11. Push Adapter Interface

Use adapter pattern so FCM is default but replaceable later.

abstract class PushAdapter {
  String get provider;

  Future<void> init();

  Future<bool> requestPermission();

  Future<String?> getToken();

  Future<void> deleteToken();

  Stream<PushMessage> get onMessage;

  Stream<PushMessage> get onMessageOpenedApp;

  Future<void> dispose();
}


---

12. FCM Push Adapter

class FcmPushAdapter implements PushAdapter {
  @override
  String get provider => 'fcm';

  final _onMessageController = StreamController<PushMessage>.broadcast();

  final _onOpenedController = StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => _onOpenedController.stream;

  @override
  Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onMessageController.add(PushMessage.fromFcm(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onOpenedController.add(PushMessage.fromFcm(message));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _onOpenedController.add(PushMessage.fromFcm(initialMessage));
    }
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() {
    return FirebaseMessaging.instance.deleteToken();
  }

  @override
  Future<void> dispose() async {
    await _onMessageController.close();
    await _onOpenedController.close();
  }
}


---

13. Local Notification Adapter

abstract class LocalNotificationAdapter {
  Future<void> init();

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload,
  });

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload,
  });

  Future<void> cancel(String id);

  Future<void> cancelAll();
}

Implementation wraps flutter_local_notifications.

class FlutterLocalNotificationAdapter implements LocalNotificationAdapter {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Decode payload and pass to Velora.notify handler.
      },
    );
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );
  }

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) async {
    // Implement scheduled notification.
  }

  @override
  Future<void> cancel(String id) async {
    await plugin.cancel(id.hashCode);
  }

  @override
  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }
}


---

14. Notification Entity

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? feature;
  final String? permission;
  final String? route;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.feature,
    this.permission,
    this.route,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  bool get isUnread => readAt == null;

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? feature,
    String? permission,
    String? route,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      feature: feature ?? this.feature,
      permission: permission ?? this.permission,
      route: route ?? this.route,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      feature: json['feature'],
      permission: json['permission'],
      route: json['route'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


---

15. Push Message Entity

class PushMessage {
  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const PushMessage({
    this.id,
    this.title,
    this.body,
    this.data = const {},
  });

  factory PushMessage.fromFcm(RemoteMessage message) {
    return PushMessage(
      id: message.messageId,
      title: message.notification?.title ?? message.data['title'],
      body: message.notification?.body ?? message.data['body'],
      data: message.data,
    );
  }
}


---

16. Notification Payload Standard

Laravel should send this payload through FCM:

{
  "notification_id": "uuid-or-id",
  "type": "users.created",
  "title": "New user created",
  "body": "Rahim was added by Admin",
  "feature": "users",
  "permission": "users.view",
  "route": "/users/15",
  "data": {
    "user_id": 15
  }
}

Recommended rule:

Every remote push should include enough data for feature-aware routing.

Minimum required fields:

title
body
type

Recommended rule:
Every remote push should include enough data for feature-aware routing.
Minimum required fields:
title
body
type
Recommended fields:
notification_id
feature
permission
route
data
17. Feature + Permission-Aware Handling
Notification action must be blocked if the user cannot access the feature.
bool canHandleNotification(AppNotification notification) {
  if (notification.feature != null &&
      !Velora.feature.enabled(notification.feature!)) {
    return false;
  }

  if (notification.permission != null &&
      !Velora.permission.can(notification.permission!)) {
    return false;
  }

  return true;
}
Tap handling:
Future<void> handleTap(AppNotification notification) async {
  if (!Velora.auth.check) {
    Velora.nav.to('/login');
    return;
  }

  if (!canHandleNotification(notification)) {
    Velora.nav.to('/403');
    return;
  }

  await markAsRead(notification.id);

  if (notification.route != null) {
    Velora.nav.to(notification.route!);
  }
}
This prevents disabled module dependencies from starting.
18. Binding
class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(),
      fenix: false,
    );

    Get.lazyPut<NotificationRepository>(
      () => NotificationRepositoryImpl(
        Get.find<NotificationRemoteDataSource>(),
      ),
      fenix: false,
    );

    Get.lazyPut<NotificationService>(
      () => NotificationService(
        repository: Get.find<NotificationRepository>(),
        pushAdapter: FcmPushAdapter(),
        localAdapter: FlutterLocalNotificationAdapter(),
      ),
      fenix: false,
    );

    Get.lazyPut<NotificationsController>(
      () => NotificationsController(
        Get.find<NotificationService>(),
      ),
      fenix: false,
    );
  }
}
But for framework core, NotificationService should be user-scoped, not page-scoped.
Better:
NotificationService starts after login.
Notification page controller starts only when notification page opens.
Core boot:
Get.put<NotificationService>(
  NotificationService(
    repository: Get.find<NotificationRepository>(),
    pushAdapter: FcmPushAdapter(),
    localAdapter: FlutterLocalNotificationAdapter(),
  ),
  permanent: true,
);
Then:
await Velora.notify.initForUser();
On logout:
await Velora.notify.disposeForUser();
19. Auth Lifecycle Integration
After login:
Future<void> login(...) async {
  final result = await authRepository.login(...);

  await setUser(result.user);
  await setToken(result.token);

  Velora.feature.syncFromUser(result.user);

  if (Velora.config.notifications.enabled &&
      Velora.config.notifications.requestPermissionAfterLogin) {
    await Velora.notify.initForUser();
  }

  Velora.nav.offAll('/dashboard');
}
On logout:
Future<void> logout() async {
  await Velora.notify.disposeForUser();

  await authRepository.logout();

  await clearSession();

  await Velora.feature.flushUserScope();

  Velora.nav.offAll('/login');
}
20. Laravel API Contract
20.1 Device Registration
POST /api/devices
Request:
{
  "token": "fcm-token",
  "provider": "fcm",
  "platform": "android",
  "device_name": "Pixel 8",
  "app_version": "1.0.0"
}
Response:
{
  "success": true,
  "message": "Device registered"
}
20.2 Device Unregister
DELETE /api/devices
Request:
{
  "token": "fcm-token"
}
20.3 Notification List
GET /api/notifications
Response:
{
  "success": true,
  "data": [
    {
      "id": "9c1b7c10-0000-4000-9000-111111111111",
      "type": "users.created",
      "title": "New user created",
      "body": "Rahim was added by Admin",
      "feature": "users",
      "permission": "users.view",
      "route": "/users/15",
      "data": {
        "user_id": 15
      },
      "read_at": null,
      "created_at": "2026-06-24T10:30:00Z"
    }
  ]
}

20.4 Mark as Read
POST /api/notifications/{id}/read
20.5 Mark All as Read
POST /api/notifications/read-all
21. Laravel Database Design
device_tokens
id
user_id
token
provider
platform
device_name
app_version
last_used_at
revoked_at
created_at
updated_at
Recommended unique index:
unique(user_id, token)
app_notifications
id
user_id
type
feature
permission
title
body
route
data json
read_at
created_at
updated_at
Why custom table instead of only Laravel default notifications table?
Because Velora needs:
feature
permission
route
title
body
read_at
data
Laravel’s built-in notification table can still work, but custom table gives cleaner frontend contracts.
22. Laravel Notification Sending Flow
Recommended backend flow:
Business event happens
  ↓
Create app_notifications row
  ↓
Dispatch push notification job
  ↓
Job gets active device tokens
  ↓
Send to FCM
Example event:
UserCreated
Creates:
{
  "type": "users.created",
  "feature": "users",
  "permission": "users.view",
  "title": "New user created",
  "body": "Rahim was added by Admin",
  "route": "/users/15"
}
Then push payload sent to FCM.
23. Web Push Requirements
For Flutter Web + FCM:
Need:
web/firebase-messaging-sw.js
web/index.html Firebase config
VAPID key setup
Velora CLI should generate:
web/firebase-messaging-sw.js
Example service worker placeholder:
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    data: payload.data,
  });
});
The CLI should generate placeholders, not hardcode real Firebase credentials.
24. Android Requirements
CLI should document/generate reminders for:
android/app/google-services.json
android/build.gradle plugin setup
android/app/build.gradle plugin setup
Android notification permission for Android 13+
Default notification channel
Also add permission:
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
25. iOS Requirements
CLI should document/generate reminders for:
ios/Runner/GoogleService-Info.plist
Push Notifications capability
Background Modes → Remote notifications
APNs key uploaded to Firebase Console
Notification permission prompt
26. Notification Center UI
Generated page:
/notifications
Features:
- List notifications
- Show unread badge
- Pull to refresh
- Mark single as read
- Mark all as read
- Tap notification to route
- Empty state
- Loading state
- Error state
Permission:
notifications.view
Route:
GetPage(
  name: NotificationsRoutes.index,
  page: () => const NotificationsIndexPage(),
  binding: NotificationsBinding(),
  middlewares: [
    VeloraRouteGuard(
      feature: 'notifications',
      permission: 'notifications.view',
    ),
  ],
);
27. Badge Widget
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = Velora.notify.unreadCount.value;

      if (count == 0) {
        return const SizedBox.shrink();
      }

      return Text(count > 99 ? '99+' : '$count');
    });
  }
}
Usage:
IconButton(
  icon: Stack(
    children: [
      const Icon(Icons.notifications),
      const NotificationBadge(),
    ],
  ),
  onPressed: () => Velora.nav.to('/notifications'),
);

28. CLI Commands
Add these commands:
velora make:notifications
Generates notification module.
velora install:push --fcm
Adds Firebase Messaging setup files and docs.
velora install:push --local
Adds local notification adapter only.
velora notify:test
Optional future command to test local notification.
29. AI-Ready Files
Update generated .ai folder:
.ai/notifications.md
.ai/feature-map.json
.ai/api-contract.md
.ai/module-map.json
.ai/notifications.md
Must include:
# Notification Architecture

Velora notifications use:

- NotificationService as GetxService single source of truth
- NotificationRepository for Laravel API access
- FcmPushAdapter for remote push
- LocalNotificationAdapter for local display
- Feature-aware routing
- Permission-aware display

Do not store notification state in controllers.

Do not directly use FirebaseMessaging inside views/controllers.

Do not directly use FlutterLocalNotificationsPlugin inside views/controllers.

Use Velora.notify facade.
30. Build Phases for AI Agent
Phase 1 — Config
Implement:
VeloraNotificationConfig
PushProvider enum
Velora.notify facade getter
Phase 2 — Entities
Implement:
AppNotification
PushMessage
DeviceToken
Phase 3 — Adapters
Implement:
PushAdapter
FcmPushAdapter
NoopPushAdapter
LocalNotificationAdapter
FlutterLocalNotificationAdapter
Phase 4 — Repository
Implement:
NotificationRepository
NotificationRepositoryImpl
NotificationRemoteDataSource
Phase 5 — Service
Implement:
NotificationService extends GetxService
initForUser()
disposeForUser()
fetch()
markAsRead()
markAllAsRead()
showLocal()
scheduleLocal()
handleTap()
Phase 6 — Auth Integration
Modify AuthService:
After login → Velora.notify.initForUser()
Before logout → Velora.notify.disposeForUser()
Phase 7 — UI
Generate:
NotificationBadge
NotificationsIndexPage
NotificationTile
NotificationDetailsPage
Phase 8 — CLI
Add:
make:notifications
install:push --fcm
install:push --local
Phase 9 — Platform Setup Docs
Generate docs for:
Android
iOS
Web
Laravel backend
FCM setup
31. Acceptance Criteria
Notification module is complete only when these work:
await Velora.notify.initForUser();

await Velora.notify.showLocal(
  title: 'Test',
  body: 'Hello from Velora',
);

await Velora.notify.fetch();

Velora.notify.unreadCount;

await Velora.notify.markAsRead(id);

await Velora.notify.markAllAsRead();

await Velora.notify.disposeForUser();
FCM acceptance:
- App can get FCM token
- Token is sent to Laravel /api/devices
- Foreground push can be received
- Foreground push can be shown as local notification
- Tapping push can navigate to route
- Disabled feature notification does not open feature
- Permission-blocked notification goes to 403
- Logout unregisters or clears token state
Platform acceptance:
Android: supports FCM + local notifications
iOS: supports FCM through APNs setup
Web: supports FCM through service worker
32. Final Design Decision
The official Velora notification architecture should be:
Velora.notify facade
  ↓
NotificationService GetxService
  ↓
NotificationRepository
  ↓
Laravel API

NotificationService
  ↓
FcmPushAdapter
  ↓
Firebase Cloud Messaging

NotificationService
  ↓
LocalNotificationAdapter
  ↓
flutter_local_notifications
Use FCM as the default remote push provider.
Use Laravel as the notification source of truth.
Use NotificationService as the single state truth.
Use feature and permission checks before displaying or routing notifications.