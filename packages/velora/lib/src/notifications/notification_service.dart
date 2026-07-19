import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../auth/auth_service.dart';
import '../features/feature_service.dart';
import '../permissions/permission_service.dart';
import '../routing/velora_nav.dart';
import 'adapters/local_notification_adapter.dart';
import 'adapters/push_adapter.dart';
import 'notification_config.dart';
import 'notification_event.dart';
import 'notification_payload.dart';
import 'notification_repository.dart';

/// Called when a notification is tapped so the presentation layer can decide
/// where to navigate. Return without navigating to suppress the built-in
/// routing entirely.
typedef NotificationTapHandler = Future<void> Function(
  VeloraNotification notification,
);

class NotificationService {
  final NotificationRepository repository;
  final PushAdapter pushAdapter;
  final LocalNotificationAdapter localAdapter;
  final AuthService auth;
  final FeatureService feature;
  final PermissionService permission;
  final VeloraNav nav;
  final VeloraNotificationConfig config;

  /// Optional presentation-layer navigation handler. When provided, the service
  /// delegates all tap routing to it instead of navigating itself — keeping
  /// navigation policy out of this state/service class. When null, the service
  /// falls back to config-driven routing (see [VeloraNotificationConfig]).
  final NotificationTapHandler? onNotificationTap;

  NotificationService({
    required this.repository,
    required this.pushAdapter,
    required this.localAdapter,
    required this.auth,
    required this.feature,
    required this.permission,
    required this.nav,
    required this.config,
    this.onNotificationTap,
  });

  final RxList<VeloraNotification> notifications = <VeloraNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool permissionGranted = false.obs;
  final RxBool initialized = false.obs;
  final RxnString pushToken = RxnString();
  final Rxn<NotificationEvent> lastEvent = Rxn<NotificationEvent>();

  StreamSubscription<PushMessage>? _foregroundSubscription;
  StreamSubscription<PushMessage>? _openedSubscription;

  Future<void> initForUser() async {
    if (!config.enabled || initialized.value) return;

    await localAdapter.init();
    await pushAdapter.init();
    await requestPermission();

    if (permissionGranted.value) {
      await registerDeviceToken();
    }

    _listenToForegroundMessages();
    _listenToNotificationOpenedApp();

    await fetch();
    initialized.value = true;
  }

  Future<bool> requestPermission() async {
    if (!config.enabled) {
      permissionGranted.value = false;
      return false;
    }

    permissionGranted.value = await pushAdapter.requestPermission();
    return permissionGranted.value;
  }

  Future<void> registerDeviceToken() async {
    if (!config.enabled) return;

    final token = await pushAdapter.getToken();
    if (token == null || token.isEmpty) return;

    pushToken.value = token;
    try {
      await repository.registerDeviceToken(
        token: token,
        provider: pushAdapter.provider,
        platform: VeloraPlatform.current,
      );
    } catch (_) {
      // best-effort; local state still updates
    }
  }

  Future<void> fetch() async {
    if (!config.enabled) return;

    try {
      final result = await repository.index();
      notifications.assignAll(result);
    } catch (_) {
      // best-effort; local state still updates
    }
    _recalculateUnread();
  }

  Future<void> markAsRead(String id) async {
    if (!config.enabled) return;

    try {
      await repository.markAsRead(id);
    } catch (_) {
      // best-effort; local state still updates
    }

    final index = notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(
        readAt: DateTime.now(),
      );
    }

    _recalculateUnread();
  }

  Future<void> markAllAsRead() async {
    if (!config.enabled) return;

    try {
      await repository.markAllAsRead();
    } catch (_) {
      // best-effort; local state still updates
    }
    final now = DateTime.now();
    notifications.assignAll(
      notifications
          .map((item) => item.copyWith(readAt: now))
          .toList(growable: false),
    );
    _recalculateUnread();
  }

  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    if (!config.enabled) return;

    await localAdapter.show(title: title, body: body, payload: payload);
    lastEvent.value = NotificationEvent(
      type: NotificationEventType.localShown,
      data: payload,
    );
  }

  Future<void> scheduleLocal({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) async {
    if (!config.enabled) return;

    await localAdapter.schedule(
      id: id,
      title: title,
      body: body,
      dateTime: dateTime,
      payload: payload,
    );
    lastEvent.value = NotificationEvent(
      type: NotificationEventType.localScheduled,
      data: {'id': id, ...payload},
    );
  }

  Future<void> cancelLocal(String id) {
    return localAdapter.cancel(id);
  }

  Future<void> cancelAllLocal() {
    return localAdapter.cancelAll();
  }

  bool canHandleNotification(VeloraNotification notification) {
    if (!auth.check) return false;

    final requiredFeature = notification.feature;
    if (requiredFeature != null &&
        requiredFeature.isNotEmpty &&
        !feature.enabled(requiredFeature)) {
      return false;
    }

    final requiredPermission = notification.permission;
    if (requiredPermission != null &&
        requiredPermission.isNotEmpty &&
        !permission.can(requiredPermission)) {
      return false;
    }

    return true;
  }

  Future<void> handleTap(VeloraNotification notification) async {
    lastEvent.value = NotificationEvent(
      type: NotificationEventType.tapped,
      notification: notification,
    );

    // Delegate navigation to the app when a handler is wired.
    final handler = onNotificationTap;
    if (handler != null) {
      if (auth.check && canHandleNotification(notification)) {
        await markAsRead(notification.id);
      }
      await handler(notification);
      return;
    }

    // Built-in fallback routing, using configurable routes (not hardcoded).
    final routes = config;
    if (!auth.check) {
      nav.to(routes.unauthenticatedRoute);
      return;
    }

    if (!canHandleNotification(notification)) {
      nav.to(routes.forbiddenRoute);
      return;
    }

    await markAsRead(notification.id);

    final route = notification.route;
    if (route != null && route.isNotEmpty) {
      nav.to(route);
    }
  }

  Future<void> disposeForUser() async {
    try {
      final token = pushToken.value;
      if (token != null && token.isNotEmpty) {
        await repository.unregisterDeviceToken(token: token);
      }

      await pushAdapter.deleteToken();
      await pushAdapter.dispose();
    } finally {
      await _foregroundSubscription?.cancel();
      await _openedSubscription?.cancel();
      _foregroundSubscription = null;
      _openedSubscription = null;

      notifications.clear();
      unreadCount.value = 0;
      permissionGranted.value = false;
      initialized.value = false;
      pushToken.value = null;
      lastEvent.value = null;
    }
  }

  void _listenToForegroundMessages() {
    _foregroundSubscription ??= pushAdapter.onMessage.listen((message) async {
      final notification = AppNotification.fromPushMessage(message);
      lastEvent.value = NotificationEvent(
        type: NotificationEventType.foregroundMessage,
        notification: notification,
        message: message,
        data: message.data,
      );

      if (!canHandleNotification(notification)) return;

      if (config.showForegroundRemoteAsLocal) {
        await showLocal(
          title: notification.title,
          body: notification.body,
          payload: notification.data,
        );
      }

      if (config.syncInAppNotificationsAfterPush) {
        await fetch();
      }
    });
  }

  void _listenToNotificationOpenedApp() {
    _openedSubscription ??= pushAdapter.onMessageOpenedApp.listen((
      message,
    ) async {
      final notification = AppNotification.fromPushMessage(message);
      lastEvent.value = NotificationEvent(
        type: NotificationEventType.openedApp,
        notification: notification,
        message: message,
        data: message.data,
      );
      await handleTap(notification);
    });
  }

  void _recalculateUnread() {
    unreadCount.value = notifications
        .where((item) => item.readAt == null)
        .length;
  }
}

class VeloraPlatform {
  static String get current {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
