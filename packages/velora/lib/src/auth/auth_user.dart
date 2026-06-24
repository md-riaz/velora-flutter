class AuthUser {
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final List<String> features;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.roles = const [],
    this.permissions = const [],
    this.features = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
      features: _stringList(json['features']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
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
