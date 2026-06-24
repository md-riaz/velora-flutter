import '../notification_payload.dart';

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
