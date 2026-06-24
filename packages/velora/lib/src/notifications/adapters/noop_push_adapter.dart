import 'dart:async';

import '../notification_payload.dart';
import 'push_adapter.dart';

class NoopPushAdapter implements PushAdapter {
  final bool permissionGranted;
  final String? token;
  final _onMessageController = StreamController<PushMessage>.broadcast();
  final _onOpenedController = StreamController<PushMessage>.broadcast();
  bool initialized = false;
  bool disposed = false;

  NoopPushAdapter({this.permissionGranted = false, this.token});

  @override
  String get provider => 'none';

  @override
  Stream<PushMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => _onOpenedController.stream;

  @override
  Future<void> init() async {
    initialized = true;
    disposed = false;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void emitMessage(PushMessage message) {
    if (!_onMessageController.isClosed) {
      _onMessageController.add(message);
    }
  }

  void emitOpenedApp(PushMessage message) {
    if (!_onOpenedController.isClosed) {
      _onOpenedController.add(message);
    }
  }
}
