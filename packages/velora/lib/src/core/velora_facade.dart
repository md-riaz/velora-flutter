import 'package:get/get.dart';

import '../auth/auth_service.dart';
import '../auth/auth_user.dart';
import '../auth/logout_coordinator.dart';
import '../config/velora_config.dart';
import '../features/feature_service.dart';
import '../http/velora_api_interceptor.dart';
import '../http/velora_api_service.dart';
import '../notifications/adapters/local_notification_adapter.dart';
import '../notifications/adapters/noop_push_adapter.dart';
import '../notifications/adapters/push_adapter.dart';
import '../notifications/notification_remote_datasource.dart';
import '../notifications/notification_repository.dart';
import '../notifications/notification_service.dart';
import '../notifications/velora_notify.dart';
import '../permissions/permission_service.dart';
import '../routing/velora_nav.dart';
import '../routing/velora_route_guard.dart';
import '../storage/velora_storage_service.dart';
import '../theme/theme_service.dart';
import '../ui/velora_dialog.dart';
import '../ui/velora_loader.dart';
import '../ui/velora_toast.dart';
import '../media/velora_media_service.dart';
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
  static VeloraMediaService get media => Get.find<VeloraMediaService>();
  static const VeloraValidator validator = VeloraValidator();

  static Future<AuthUser> login(Map<String, dynamic> credentials) =>
      auth.login(credentials);

  static Future<void> logout() => auth.logout();

  // ---------------------------------------------------------------------------
  // Route guard shorthands — use directly in GetPage.middlewares:
  //
  //   GetPage(name: '/home',  page: () => HomePage(),  middlewares: Velora.authOnly)
  //   GetPage(name: '/login', page: () => LoginPage(), middlewares: Velora.guestOnly)
  // ---------------------------------------------------------------------------

  /// Requires the user to be authenticated; redirects to login otherwise.
  static List<GetMiddleware> get authOnly =>
      [VeloraMiddleware(guards: const [VeloraAuthGuard()])];

  /// Requires the user to be a guest; redirects to [authenticatedRoute] otherwise.
  static List<GetMiddleware> guestOnly({String authenticatedRoute = '/'}) =>
      [VeloraMiddleware(guards: [VeloraGuestGuard(authenticatedRoute: authenticatedRoute)])];

  /// Wrap arbitrary guards into a middleware list.
  static List<GetMiddleware> guard(List<VeloraRouteGuard> guards) =>
      [VeloraMiddleware(guards: guards)];

  // ---------------------------------------------------------------------------

  static Future<void> boot({
    required VeloraConfig config,

    /// HTTP interceptors applied (in order) after the built-in auth injector.
    List<VeloraApiInterceptor> interceptors = const [],

    /// Custom push adapter. Defaults to [NoopPushAdapter].
    /// Pass a [FcmPushAdapter] (wired with firebase_messaging) for real push.
    PushAdapter? pushAdapter,
  }) async {
    Velora.config = config;

    // Also register VeloraConfig in GetX so guards can find it.
    Get.put<VeloraConfig>(config, permanent: true);

    final storage = await VeloraStorageService().init();
    Get.put<VeloraStorageService>(storage, permanent: true);

    final api = VeloraApiService(
      config: config,
      storage: storage,
      interceptors: interceptors,
    );
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

    final notificationRepository = NotificationRepositoryImpl(notificationRemote);
    Get.put<NotificationRepository>(notificationRepository, permanent: true);

    final notify = VeloraNotify(
      repository: notificationRepository,
      pushAdapter: pushAdapter ?? NoopPushAdapter(),
      localAdapter: InMemoryLocalNotificationAdapter(),
    );
    Get.put<VeloraNotify>(notify, permanent: true);
    Get.put<NotificationService>(notify, permanent: true);
    auth.attachNotifications(notify);

    Get.put<PermissionService>(
      PermissionService(
        auth: auth,
        permissionResolver: config.auth.permissionResolver,
      ),
      permanent: true,
    );
    final feature = FeatureService();
    Get.put<FeatureService>(feature, permanent: true);
    lifecycle.register(feature);
    final themeService = await ThemeService(storage: storage).init();
    Get.put<ThemeService>(themeService, permanent: true);
    Get.put<VeloraNav>(VeloraNav(), permanent: true);
    Get.put<VeloraToast>(VeloraToast(), permanent: true);
    Get.put<VeloraDialog>(VeloraDialog(), permanent: true);
    Get.put<VeloraLoader>(VeloraLoader(), permanent: true);
    Get.put<VeloraMediaService>(VeloraMediaService(), permanent: true);
  }
}
