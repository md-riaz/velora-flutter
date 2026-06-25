import '../auth/auth_user.dart';
import '../notifications/notification_config.dart';

/// Configures how [ApiResponse.fromJson] unwraps your API's JSON envelope.
///
/// Override the defaults to match your backend's response shape:
///
/// ```dart
/// // Backend returns: {"ok": true, "payload": {...}, "error": "..."}
/// VeloraResponseConfig(
///   successKey: 'ok',
///   dataKey: 'payload',
///   messageKey: 'error',
/// )
/// ```
class VeloraResponseConfig {
  /// JSON key whose boolean value signals success. Defaults to `'success'`.
  final String successKey;

  /// JSON key that holds the response payload. Defaults to `'data'`.
  final String dataKey;

  /// JSON key that holds a human-readable message. Defaults to `'message'`.
  final String messageKey;

  /// JSON key that holds field-level validation errors. Defaults to `'errors'`.
  final String errorsKey;

  const VeloraResponseConfig({
    this.successKey = 'success',
    this.dataKey = 'data',
    this.messageKey = 'message',
    this.errorsKey = 'errors',
  });
}

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

  /// Controls how API responses are unwrapped. Override when your backend
  /// uses different envelope keys than the defaults.
  final VeloraResponseConfig response;

  /// Typed config extensions. Retrieve with [extension<T>()].
  final List<VeloraConfigExtension> extensions;

  const VeloraConfig({
    required this.appName,
    required this.apiBaseUrl,
    this.auth = const VeloraAuthConfig(),
    this.notifications = const VeloraNotificationConfig(),
    this.response = const VeloraResponseConfig(),
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

  /// Extracts the bearer token from the login response payload.
  ///
  /// Override when your API uses a different token field name:
  /// ```dart
  /// VeloraAuthConfig(
  ///   tokenExtractor: (payload) => payload['jwt']?.toString(),
  /// )
  /// ```
  /// Defaults to checking `token` then `access_token`.
  final String? Function(Map<String, dynamic> payload)? tokenExtractor;

  /// Extracts the user map from the login response payload.
  ///
  /// Override when your API nests the user under a different key:
  /// ```dart
  /// VeloraAuthConfig(
  ///   userExtractor: (payload) => payload['account'] as Map<String, dynamic>?,
  /// )
  /// ```
  /// Defaults to reading the `user` key, falling back to the whole payload.
  final Map<String, dynamic>? Function(Map<String, dynamic> payload)?
      userExtractor;

  /// Extracts the user map from the /me endpoint response payload.
  ///
  /// Defaults to reading the `user` key, falling back to the whole payload.
  final Map<String, dynamic>? Function(Map<String, dynamic> payload)?
      meUserExtractor;

  /// Controls how [PermissionService.can] resolves a permission string.
  ///
  /// By default, `can(p)` returns true when `p` appears in
  /// [AuthUser.permissions]. Override this to support other access-control
  /// models without changing any call sites:
  ///
  /// **Roles only** — admin can do everything, editor has limited access:
  /// ```dart
  /// permissionResolver: (user, permission) {
  ///   if (user.roles.contains('admin')) return true;
  ///   if (user.roles.contains('editor')) {
  ///     return const ['posts.view', 'posts.create'].contains(permission);
  ///   }
  ///   return false;
  /// },
  /// ```
  ///
  /// **Resource permissions only** — no override needed; [AuthUser.permissions]
  /// can hold any strings your backend returns (`'posts:read'`, `'users:write'`,
  /// etc.) and the default resolver handles them transparently.
  ///
  /// **Hybrid** — check permissions first, fall back to role wildcard:
  /// ```dart
  /// permissionResolver: (user, permission) =>
  ///     user.permissions.contains(permission) ||
  ///     user.roles.contains('superadmin'),
  /// ```
  final bool Function(AuthUser user, String permission)? permissionResolver;

  const VeloraAuthConfig({
    this.loginEndpoint = '/auth/login',
    this.logoutEndpoint = '/auth/logout',
    this.meEndpoint = '/auth/me',
    this.logoutRedirectRoute = '/login',
    this.tokenExtractor,
    this.userExtractor,
    this.meUserExtractor,
    this.permissionResolver,
  });
}
