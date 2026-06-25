import 'notification_config.dart';
import '../http/velora_api_service.dart';
import 'notification_payload.dart';

class NotificationRemoteDataSource {
  final VeloraApiService api;
  final VeloraNotificationConfig config;

  NotificationRemoteDataSource({required this.api, required this.config});

  Future<List<VeloraNotification>> index() async {
    final response = await api.get<List<VeloraNotification>>(
      config.notificationsEndpoint,
      parser: _parseNotifications,
    );
    return response.data ?? const <VeloraNotification>[];
  }

  Future<void> markAsRead(String id) async {
    await api.post<Object?>(_endpoint(config.markAsReadEndpoint, id));
  }

  Future<void> markAllAsRead() async {
    await api.post<Object?>(config.markAllAsReadEndpoint);
  }

  Future<void> registerDeviceToken({
    required String token,
    required String provider,
    required String platform,
  }) async {
    await api.post<Object?>(
      config.deviceRegisterEndpoint,
      data: {'token': token, 'provider': provider, 'platform': platform},
    );
  }

  Future<void> unregisterDeviceToken({required String token}) async {
    await api.delete<Object?>(
      config.deviceUnregisterEndpoint,
      data: {'token': token},
    );
  }

  List<VeloraNotification> _parseNotifications(Object? value) {
    final items = switch (value) {
      List() => value,
      {'data': final List data} => data,
      {'notifications': final List notifications} => notifications,
      _ => const <Object?>[],
    };

    final parse = config.notificationParser ?? AppNotification.fromJson;
    return items
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  String _endpoint(String template, String id) {
    return template.replaceAll('{id}', Uri.encodeComponent(id));
  }
}
