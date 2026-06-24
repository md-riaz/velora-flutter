import '../notifications/notification_config.dart';

/// Marker base class for typed config extensions.
///
/// Create a subclass to attach custom configuration to [VeloraConfig] without
/// reaching for an untyped `Map`:
///
/// ```dart
/// class AnalyticsConfig extends VeloraConfigExtension {
///   final String apiKey;
///   const AnalyticsConfig({required this.apiKey});
/// }
///
/// final config = VeloraConfig(
///   appName: 'My App',
///   apiBaseUrl: 'https://api.example.com',
///   extensions: [const AnalyticsConfig(apiKey: 'xyz')],
/// );
///
/// // Access anywhere:
/// final analytics = Velora.config.extension<AnalyticsConfig>();
/// ```
abstract class VeloraConfigExtension {
  const VeloraConfigExtension();
}

class VeloraConfig {
  final String appName;
  final String apiBaseUrl;
  final VeloraAuthConfig auth;
  final VeloraNotificationConfig notifications;

  /// Typed config extensions. Retrieve with [extension<T>()].
  final List<VeloraConfigExtension> extensions;

  const VeloraConfig({
    required this.appName,
    required this.apiBaseUrl,
    this.auth = const VeloraAuthConfig(),
    this.notifications = const VeloraNotificationConfig(),
    this.extensions = const [],
  });

  /// Returns the first registered extension of type [T], or null if none.
  T? extension<T extends VeloraConfigExtension>() {
    for (final ext in extensions) {
      if (ext is T) return ext;
    }
    return null;
  }
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
