/// Interface for authenticated user models.
///
/// Implement this (or use the built-in [AuthUser]) to bring your own user model
/// with custom fields, ID types, and parsing logic.
///
/// ```dart
/// class AppUser implements VeloraUser {
///   final String uuid;          // UUID instead of int
///   final String name;
///   final String? phone;        // phone/OTP auth — no email
///   @override final List<String> roles;
///   @override final List<String> permissions;
///   @override final List<String> features;
///
///   static AppUser fromJson(Map<String, dynamic> json) => AppUser(
///     uuid: json['uuid']?.toString() ?? '',
///     name: json['name']?.toString() ?? '',
///     phone: json['phone']?.toString(),
///     roles: _list(json['roles']),
///     permissions: _list(json['permissions']),
///     features: _list(json['features']),
///   );
///
///   @override Map<String, dynamic> toJson() => {'uuid': uuid, ...};
/// }
/// ```
abstract class VeloraUser {
  List<String> get roles;
  List<String> get permissions;
  List<String> get features;
  Map<String, dynamic> toJson();
}

/// Built-in user model — use as-is when your backend matches the default shape.
///
/// Override with your own class implementing [VeloraUser] when you need custom
/// fields, a different ID type, or non-standard JSON keys.
class AuthUser implements VeloraUser {
  final int id;
  final String name;

  /// Nullable — backends using phone/OTP/username auth may not send an email.
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
