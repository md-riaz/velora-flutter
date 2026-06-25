import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/velora_facade.dart';
import 'adapters/local_notification_adapter.dart';
import 'adapters/push_adapter.dart';
import 'notification_event.dart';
import 'notification_payload.dart';
import 'notification_repository.dart';

class NotificationService {
  final NotificationRepository repository;
  final PushAdapter pushAdapter;
  final LocalNotificationAdapter localAdapter;

  NotificationService({
    required this.repository,
    required this.pushAdapter,
    required this.localAdapter,
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
    if (!Velora.config.notifications.enabled || initialized.value) return;

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
    if (!Velora.config.notifications.enabled) {
      permissionGranted.value = false;
      return false;
    }

    permissionGranted.value = await pushAdapter.requestPermission();
    return permissionGranted.value;
  }

  Future<void> registerDeviceToken() async {
    if (!Velora.config.notifications.enabled) return;

    final token = await pushAdapter.getToken();
    if (token == null || token.isEmpty) return;

    pushToken.value = token;
    await repository.registerDeviceToken(
      token: token,
      provider: pushAdapter.provider,
      platform: VeloraPlatform.current,
    );
  }

  Future<void> fetch() async {
    if (!Velora.config.notifications.enabled) return;

    final result = await repository.index();
    notifications.assignAll(result);
    _recalculateUnread();
  }

  Future<void> markAsRead(String id) async {
    if (!Velora.config.notifications.enabled) return;

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
    if (!Velora.config.notifications.enabled) return;

    await repository.markAllAsRead();
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
    if (!Velora.config.notifications.enabled) return;

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
    if (!Velora.config.notifications.enabled) return;

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
    if (!Velora.auth.check) return false;

    final feature = notification.feature;
    if (feature != null &&
        feature.isNotEmpty &&
        !Velora.feature.enabled(feature)) {
      return false;
    }

    final permission = notification.permission;
    if (permission != null &&
        permission.isNotEmpty &&
        !Velora.permission.can(permission)) {
      return false;
    }

    return true;
  }

  Future<void> handleTap(VeloraNotification notification) async {
    lastEvent.value = NotificationEvent(
      type: NotificationEventType.tapped,
      notification: notification,
    );

    if (!Velora.auth.check) {
      Velora.nav.to('/login');
      return;
    }

    if (!canHandleNotification(notification)) {
      Velora.nav.to('/403');
      return;
    }

    await markAsRead(notification.id);

    final route = notification.route;
    if (route != null && route.isNotEmpty) {
      Velora.nav.to(route);
    }
  }

  Future<void> disposeForUser() async {
    final token = pushToken.value;
    if (token != null && token.isNotEmpty) {
      await repository.unregisterDeviceToken(token: token);
    }

    await pushAdapter.deleteToken();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
    await pushAdapter.dispose();

    notifications.clear();
    unreadCount.value = 0;
    permissionGranted.value = false;
    initialized.value = false;
    pushToken.value = null;
    lastEvent.value = null;
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
