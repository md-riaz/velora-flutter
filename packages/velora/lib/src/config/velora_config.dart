import '../notifications/notification_config.dart';

class VeloraConfig {
  final String appName;
  final String apiBaseUrl;
  final VeloraAuthConfig auth;
  final VeloraNotificationConfig notifications;
  final Map<String, Object?> values;

  const VeloraConfig({
    required this.appName,
    required this.apiBaseUrl,
    this.auth = const VeloraAuthConfig(),
    this.notifications = const VeloraNotificationConfig(),
    this.values = const {},
  });
}

class VeloraAuthConfig {
  final String loginEndpoint;
  final String logoutEndpoint;
  final String meEndpoint;
  final String logoutRedirectRoute;

  const VeloraAuthConfig({
    this.loginEndpoint = '/auth/login',
    this.logoutEndpoint = '/auth/logout',
    this.meEndpoint = '/auth/me',
    this.logoutRedirectRoute = '/login',
  });
}
