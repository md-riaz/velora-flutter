/// The only contract Velora requires from any user model.
///
/// Implement this in your own class — Velora never forces a fixed shape on
/// your domain. Keep every field your app needs; the framework only reads
/// [roles], [permissions], and [features] for access-control decisions.
///
/// ```dart
/// class AppUser implements VeloraUser {
///   final String id;       // UUID? int? String — your choice
///   final String username;
///   final String? phone;
///   final String? email;
///   final String avatarUrl;
///
///   @override final List<String> roles;
///   @override final List<String> permissions;
///   @override final List<String> features;
///
///   static AppUser fromJson(Map<String, dynamic> json) => AppUser(...);
///
///   @override
///   Map<String, dynamic> toJson() => {...};
/// }
/// ```
///
/// Register the parser at boot so Velora knows how to restore the session:
/// ```dart
/// VeloraAuthConfig(userParser: AppUser.fromJson)
/// ```
///
/// Access the typed user anywhere:
/// ```dart
/// final user = Velora.auth.userAs<AppUser>();
/// ```
abstract class VeloraUser {
  List<String> get roles;
  List<String> get permissions;
  List<String> get features;

  /// Called by Velora to persist the session across restarts.
  /// Return a Map that [VeloraAuthConfig.userParser] can reconstruct.
  Map<String, dynamic> toJson();
}

/// Built-in user model — a ready-to-use [VeloraUser] implementation for apps
/// that don't need custom fields beyond id, name, email, roles, permissions,
/// and features.
///
/// For anything beyond these fields, implement [VeloraUser] directly in your
/// own class and register it via [VeloraAuthConfig.userParser].
class AuthUser implements VeloraUser {
  final int id;
  final String name;

  /// Null when the backend does not use email-based auth (phone / OTP /
  /// username-only flows). Always check for null before displaying or submitting.
  final String? email;

  @override
  final List<String> roles;

  @override
  final List<String> permissions;

  @override
  final List<String> features;

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.roles = const [],
    this.permissions = const [],
    this.features = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
      features: _stringList(json['features']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      'roles': roles,
      'permissions': permissions,
      'features': features,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
