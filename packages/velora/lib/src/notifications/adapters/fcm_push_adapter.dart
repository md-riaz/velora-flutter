import 'noop_push_adapter.dart';

/// FCM transport hook.
///
/// The core package intentionally avoids mandatory Firebase dependencies.
/// Apps that need Firebase can provide their own PushAdapter implementation,
/// or override this class in an integration package.
class FcmPushAdapter extends NoopPushAdapter {
  FcmPushAdapter() : super(permissionGranted: false);

  @override
  String get provider => 'fcm';
}
