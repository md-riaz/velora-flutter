import 'package:get/get.dart';

import '../auth/auth_service.dart';
import '../auth/logout_coordinator.dart';
import '../config/velora_config.dart';
import '../features/feature_service.dart';
import '../http/velora_api_service.dart';
import '../notifications/adapters/fcm_push_adapter.dart';
import '../notifications/adapters/local_notification_adapter.dart';
import '../notifications/adapters/noop_push_adapter.dart';
import '../notifications/notification_config.dart';
import '../notifications/notification_remote_datasource.dart';
import '../notifications/notification_repository.dart';
import '../notifications/notification_service.dart';
import '../notifications/velora_notify.dart';
import '../permissions/permission_service.dart';
import '../routing/velora_nav.dart';
import '../storage/velora_storage_service.dart';
import '../theme/theme_service.dart';
import '../ui/velora_dialog.dart';
import '../ui/velora_loader.dart';
import '../ui/velora_toast.dart';
import '../validation/velora_validator.dart';
import 'velora_lifecycle.dart';

class Velora {
  static late VeloraConfig config;

  static VeloraApiService get api => Get.find<VeloraApiService>();
  static AuthService get auth => Get.find<AuthService>();
  static LogoutCoordinator get logoutCoordinator =>
      Get.find<LogoutCoordinator>();
  static VeloraNotify get notify => Get.find<VeloraNotify>();
  static VeloraStorageService get storage => Get.find<VeloraStorageService>();
  static VeloraNav get nav => Get.find<VeloraNav>();
  static VeloraToast get toast => Get.find<VeloraToast>();
  static VeloraDialog get dialog => Get.find<VeloraDialog>();
  static VeloraLoader get loader => Get.find<VeloraLoader>();
  static PermissionService get permission => Get.find<PermissionService>();
  static FeatureService get feature => Get.find<FeatureService>();
  static ThemeService get theme => Get.find<ThemeService>();
  static const VeloraValidator validator = VeloraValidator();

  static Future<void> logout() => auth.logout();

  static Future<void> boot({required VeloraConfig config}) async {
    Velora.config = config;
    final storage = await VeloraStorageService().init();
    Get.put<VeloraStorageService>(storage, permanent: true);

    final api = VeloraApiService(config: config, storage: storage);
    Get.put<VeloraApiService>(api, permanent: true);

    final lifecycle = VeloraLifecycleRegistry();
    Get.put<VeloraLifecycleRegistry>(lifecycle, permanent: true);

    final logoutCoordinator = LogoutCoordinator(lifecycle: lifecycle);
    Get.put<LogoutCoordinator>(logoutCoordinator, permanent: true);

    final auth = await AuthService(
      api: api,
      storage: storage,
      config: config.auth,
      notificationConfig: config.notifications,
    ).init();
    Get.put<AuthService>(auth, permanent: true);
    auth.attachLogoutCoordinator(logoutCoordinator);
    final notificationRemote = NotificationRemoteDataSource(
      api: api,
      config: config.notifications,
    );
    Get.put<NotificationRemoteDataSource>(notificationRemote, permanent: true);

    final notificationRepository = NotificationRepositoryImpl(
      notificationRemote,
    );
    Get.put<NotificationRepository>(notificationRepository, permanent: true);

    final notify = VeloraNotify(
      repository: notificationRepository,
      pushAdapter: config.notifications.provider == PushProvider.fcm
          ? FcmPushAdapter()
          : NoopPushAdapter(),
      localAdapter: InMemoryLocalNotificationAdapter(),
    );
    Get.put<VeloraNotify>(notify, permanent: true);
    Get.put<NotificationService>(notify, permanent: true);
    auth.attachNotifications(notify);

    Get.put<PermissionService>(PermissionService(auth: auth), permanent: true);
    final feature = FeatureService();
    Get.put<FeatureService>(feature, permanent: true);
    lifecycle.register(feature);
    Get.put<ThemeService>(ThemeService(), permanent: true);
    Get.put<VeloraNav>(VeloraNav(), permanent: true);
    Get.put<VeloraToast>(VeloraToast(), permanent: true);
    Get.put<VeloraDialog>(VeloraDialog(), permanent: true);
    Get.put<VeloraLoader>(VeloraLoader(), permanent: true);
  }
}
