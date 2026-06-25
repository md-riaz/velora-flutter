import 'package:get/get.dart';

import '../config/velora_config.dart';
import '../http/velora_api_service.dart';
import '../notifications/notification_config.dart';
import '../notifications/notification_service.dart';
import '../storage/velora_storage_service.dart';
import 'auth_user.dart';
import 'logout_coordinator.dart';
import 'session_state.dart';

class AuthService extends GetxService {
  static const _userKey = 'velora.auth.user';

  final VeloraApiService api;
  final VeloraStorageService storage;
  final VeloraAuthConfig config;
  final VeloraNotificationConfig notificationConfig;
  LogoutCoordinator? _logoutCoordinator;
  NotificationService? _notifications;

  AuthService({
    required this.api,
    required this.storage,
    required this.config,
    this.notificationConfig = const VeloraNotificationConfig(),
  }) {
    ever<SessionState>(state, (value) {
      isAuthenticated.value = value == SessionState.authenticated;
    });
  }

  final Rxn<VeloraUser> currentUser = Rxn<VeloraUser>();
  final Rx<SessionState> state = SessionState.guest.obs;
  final RxBool isAuthenticated = false.obs;

  VeloraUser? get user => currentUser.value;
  T? userAs<T extends VeloraUser>() {
    final u = currentUser.value;
    return u is T ? u : null;
  }
  bool get check => state.value == SessionState.authenticated;
  bool get isLoggingOut => state.value == SessionState.loggingOut;

  void attachNotifications(NotificationService notifications) {
    _notifications = notifications;
  }

  void attachLogoutCoordinator(LogoutCoordinator coordinator) {
    _logoutCoordinator = coordinator;
  }

  Future<AuthService> init() async {
    final token = await storage.getToken();
    final json = storage.getJson(_userKey);
    if (token != null && token.isNotEmpty && json != null) {
      try {
        final parse = config.userParser ?? AuthUser.fromJson;
        currentUser.value = parse(json);
        state.value = SessionState.authenticated;
      } catch (_) {
        await _clearLocalSession();
        state.value = SessionState.guest;
      }
    } else {
      state.value = SessionState.guest;
    }
    return this;
  }

  Future<VeloraUser> login(Map<String, dynamic> credentials) async {
    state.value = SessionState.authenticating;
    try {
      final response = await api.post<Map<String, dynamic>>(
        config.loginEndpoint,
        data: credentials,
        parser: (value) => Map<String, dynamic>.from(value as Map),
        userScoped: false,
      );
      final payload = response.data ?? const <String, dynamic>{};

      final tokenExtractor = config.tokenExtractor;
      final token = tokenExtractor != null
          ? tokenExtractor(payload)
          : payload['token']?.toString() ?? payload['access_token']?.toString();

      final userExtractor = config.userExtractor;
      final rawUser = userExtractor != null
          ? userExtractor(payload)
          : (payload['user'] is Map
              ? Map<String, dynamic>.from(payload['user'] as Map)
              : Map<String, dynamic>.from(payload));

      if (token == null || token.isEmpty || rawUser == null) {
        throw StateError('Login response must include token and user.');
      }

      final parse = config.userParser ?? AuthUser.fromJson;
      final user = parse(rawUser);
      await storage.setToken(token);
      await storage.setJson(_userKey, user.toJson());
      currentUser.value = user;
      state.value = SessionState.authenticated;
      if (notificationConfig.enabled &&
          notificationConfig.requestPermissionAfterLogin) {
        await _notifications?.initForUser();
      }
      return user;
    } catch (_) {
      state.value = currentUser.value == null
          ? SessionState.guest
          : SessionState.authenticated;
      rethrow;
    }
  }

  Future<void> logout() {
    final coordinator = _logoutCoordinator;
    if (coordinator == null) {
      return _logoutWithoutCoordinator();
    }

    return coordinator.run(
      remoteLogout: _remoteLogout,
      clearSession: _clearLocalSession,
    );
  }

  Future<void> _logoutWithoutCoordinator() async {
    if (notificationConfig.enabled) {
      try {
        await _notifications?.disposeForUser();
      } catch (_) {
        // Notification teardown must not block local logout.
      }
    }
    state.value = SessionState.loggingOut;
    try {
      try {
        await _remoteLogout();
      } catch (_) {
        // Local logout must finish even if the API is offline or token expired.
      }
      await _clearLocalSession();
    } finally {
      state.value = SessionState.guest;
    }
  }

  Future<void> _remoteLogout() async {
    await api.post<Object?>(config.logoutEndpoint, userScoped: false);
  }

  Future<void> _clearLocalSession() async {
    await storage.clearToken();
    await storage.remove(_userKey);
    currentUser.value = null;
  }

  Future<VeloraUser?> me() async {
    final response = await api.get<Map<String, dynamic>>(
      config.meEndpoint,
      parser: (value) => Map<String, dynamic>.from(value as Map),
    );
    final payload = response.data;
    if (payload == null) return null;

    final meUserExtractor = config.meUserExtractor;
    final rawUser = meUserExtractor != null
        ? meUserExtractor(payload)
        : (payload.containsKey('user')
            ? (payload['user'] is Map
                ? Map<String, dynamic>.from(payload['user'] as Map)
                : null)
            : Map<String, dynamic>.from(payload));

    if (rawUser == null) return null;

    final parse = config.userParser ?? AuthUser.fromJson;
    final user = parse(rawUser);
    currentUser.value = user;
    state.value = SessionState.authenticated;
    await storage.setJson(_userKey, user.toJson());
    return user;
  }

  Future<String?> token() => storage.getToken();
}
