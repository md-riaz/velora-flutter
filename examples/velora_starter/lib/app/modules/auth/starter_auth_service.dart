import 'package:velora/velora.dart';

import '../notifications/notifications_feature.dart';
import '../users/users_feature.dart';
import 'auth_repository.dart';
import 'logout_state.dart';
import 'starter_user.dart';

class StarterAuthService extends GetxService {
  static const _userKey = 'velora.auth.user';

  final StarterAuthRepository repository;

  StarterAuthService(this.repository);

  Future<ApiResponse<StarterUser>> login(Map<String, dynamic> credentials) async {
    final response = await repository.login(credentials);
    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message ?? 'Unable to sign in.',
        errors: response.errors,
        statusCode: response.statusCode,
      );
    }

    final payload = response.data!;
    final token =
        payload['token']?.toString() ?? payload['access_token']?.toString();
    final rawUser = payload['user'];
    if (token == null || token.isEmpty || rawUser is! Map) {
      return const ApiResponse(
        success: false,
        message: 'Login response must include token and user.',
      );
    }

    final user = StarterUser.fromJson(Map<String, dynamic>.from(rawUser));
    await Velora.storage.setToken(token);
    await Velora.storage.setJson(_userKey, user.toJson());
    Velora.auth.currentUser.value = user;
    Velora.auth.state.value = SessionState.authenticated;
    await Velora.notify.initForUser();
    _syncFeatureAccess(user);

    return ApiResponse(success: true, data: user, message: response.message);
  }

  Future<ApiResponse<StarterUser?>> me() async {
    final token = await Velora.storage.getToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse(
        success: false,
        message: 'Unauthenticated.',
        statusCode: 401,
      );
    }

    final response = await repository.me(token);
    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message,
        errors: response.errors,
        statusCode: response.statusCode,
      );
    }

    final rawUser = response.data!['user'] is Map
        ? response.data!['user']
        : response.data;
    final user = StarterUser.fromJson(Map<String, dynamic>.from(rawUser as Map));
    await Velora.storage.setJson(_userKey, user.toJson());
    Velora.auth.currentUser.value = user;
    Velora.auth.state.value = SessionState.authenticated;
    _syncFeatureAccess(user);
    await Velora.notify.initForUser();
    return ApiResponse(success: true, data: user, message: response.message);
  }

  Future<void> logout() {
    if (isVeloraLogoutRunning()) return Future<void>.value();

    return Velora.logoutCoordinator.run(
      remoteLogout: () async {
        final token = await Velora.storage.getToken();
        if (token != null && token.isNotEmpty) {
          await repository.logout(token);
        }
      },
      clearSession: () async {
        await Velora.storage.clearToken();
        await Velora.storage.remove(_userKey);
        Velora.auth.currentUser.value = null;
      },
    );
  }

  void _syncFeatureAccess(StarterUser user) {
    Velora.feature.registerAll([
      UsersFeature.feature,
      NotificationsFeature.feature,
    ]);
    Velora.feature.syncFromUserFeatures(user.features);
  }
}
