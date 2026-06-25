class AuthUser {
  final int id;
  final String name;

  /// Null when the backend does not use email-based auth (e.g. phone / OTP /
  /// username-only flows). Always check for null before displaying or submitting.
  final String? email;

  /// Role labels assigned to this user (e.g. `['admin', 'editor']`).
  ///
  /// Populated from the `roles` key by default; override via
  /// [VeloraAuthConfig.userExtractor] for different field names.
  /// Empty list if the backend does not use role-based access control.
  final List<String> roles;

  /// Flat permission strings (e.g. `['users.view', 'posts:write']`).
  ///
  /// Populated from the `permissions` key by default. Empty list if the
  /// backend uses roles only — in that case configure
  /// [VeloraAuthConfig.permissionResolver] to derive access from roles.
  final List<String> permissions;

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
