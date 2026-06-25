import 'package:velora/velora.dart';

/// The starter app's own user model — demonstrates implementing [VeloraUser]
/// with your own fields, types, and parsing logic.
///
/// Add any fields your app needs here (phone, avatarUrl, subscriptionPlan, …).
/// Velora only reads [roles], [permissions], and [features]; everything else
/// is entirely yours.
class StarterUser implements VeloraUser {
  final int id;
  final String name;
  final String? email;

  @override
  final List<String> roles;

  @override
  final List<String> permissions;

  @override
  final List<String> features;

  const StarterUser({
    required this.id,
    required this.name,
    this.email,
    this.roles = const [],
    this.permissions = const [],
    this.features = const [],
  });

  static StarterUser fromJson(Map<String, dynamic> json) => StarterUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        roles: _list(json['roles']),
        permissions: _list(json['permissions']),
        features: _list(json['features']),
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        'roles': roles,
        'permissions': permissions,
        'features': features,
      };

  static List<String> _list(Object? v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).toList(growable: false);
  }
}
