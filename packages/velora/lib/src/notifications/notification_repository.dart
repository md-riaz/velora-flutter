import 'notification_payload.dart';
import 'notification_remote_datasource.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> index();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  });

  Future<void> unregisterDeviceToken({required String token});
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remote;

  NotificationRepositoryImpl(this.remote);

  @override
  Future<List<AppNotification>> index() => remote.index();

  @override
  Future<void> markAsRead(String id) => remote.markAsRead(id);

  @override
  Future<void> markAllAsRead() => remote.markAllAsRead();

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
  Future<void> unregisterDeviceToken({required String token}) {
    return remote.unregisterDeviceToken(token: token);
  }
}

class InMemoryNotificationRepository implements NotificationRepository {
  final List<AppNotification> items;
  final List<Map<String, String>> registeredTokens = <Map<String, String>>[];
  final List<String> unregisteredTokens = <String>[];

  InMemoryNotificationRepository([List<AppNotification>? initialItems])
    : items = List<AppNotification>.from(
        initialItems ?? const <AppNotification>[],
      );

  @override
  Future<List<AppNotification>> index() async =>
      List<AppNotification>.from(items);

  @override
  Future<void> markAsRead(String id) async {
    final index = items.indexWhere((item) => item.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(readAt: DateTime.now());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    for (var index = 0; index < items.length; index += 1) {
      items[index] = items[index].copyWith(readAt: now);
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  }) async {
    registeredTokens.add({
      'token': token,
      'provider': provider,
      'platform': platform,
    });
  }

  @override
  Future<void> unregisterDeviceToken({required String token}) async {
    unregisteredTokens.add(token);
  }
}
