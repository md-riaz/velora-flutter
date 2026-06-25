/// Interface for in-app notification models.
///
/// Implement this (or use the built-in [AppNotification]) to bring your own
/// notification model with custom fields, IDs, and parsing logic.
///
/// ```dart
/// class MyNotification implements VeloraNotification {
///   @override final String id;
///   @override final String title;
///   @override final String body;
///   // ... your own fields ...
///
///   @override
///   MyNotification copyWith({DateTime? readAt}) => MyNotification(
///     id: id, title: title, body: body,
///     readAt: readAt ?? this.readAt,
///   );
/// }
/// ```
abstract class VeloraNotification {
  String get id;
  String get title;
  String get body;
  Map<String, dynamic> get data;
  DateTime? get readAt;
  bool get isRead;
  bool get isUnread;
  String? get feature;
  String? get permission;
  String? get route;
  VeloraNotification copyWith({DateTime? readAt});
  Map<String, dynamic> toJson();
}

class AppNotification implements VeloraNotification {
  @override final String id;
  final String type;
  @override final String title;
  @override final String body;
  @override final String? feature;
  @override final String? permission;
  @override final String? route;
  @override final Map<String, dynamic> data;
  @override final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.feature,
    this.permission,
    this.route,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  @override
  bool get isRead => readAt != null;
  @override
  bool get isUnread => readAt == null;

  @override
  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? feature,
    String? permission,
    String? route,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      feature: feature ?? this.feature,
      permission: permission ?? this.permission,
      route: route ?? this.route,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      if (feature != null) 'feature': feature,
      if (permission != null) 'permission': permission,
      if (route != null) 'route': route,
      'data': data,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = _mapFrom(json['data']);
    return AppNotification(
      id: _string(json['id'] ?? json['notification_id']),
      type: _string(json['type']),
      title: _string(json['title'] ?? data['title']),
      body: _string(json['body'] ?? data['body']),
      feature: _nullableString(json['feature'] ?? data['feature']),
      permission: _nullableString(json['permission'] ?? data['permission']),
      route: _nullableString(json['route'] ?? data['route']),
      data: data,
      readAt: _date(json['read_at'] ?? json['readAt']),
      createdAt:
          _date(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
    );
  }

  factory AppNotification.fromPushMessage(PushMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final nestedData = _mapFrom(data['data']);
    return AppNotification(
      id: _string(data['notification_id'] ?? data['id'] ?? message.id),
      type: _string(data['type'], fallback: 'remote'),
      title: _string(message.title ?? data['title']),
      body: _string(message.body ?? data['body']),
      feature: _nullableString(data['feature']),
      permission: _nullableString(data['permission']),
      route: _nullableString(data['route']),
      data: nestedData.isEmpty ? data : nestedData,
      createdAt: DateTime.now(),
    );
  }
}

class PushMessage {
  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const PushMessage({this.id, this.title, this.body, this.data = const {}});

  factory PushMessage.fromJson(Map<String, dynamic> json) {
    return PushMessage(
      id: _nullableString(json['id'] ?? json['message_id']),
      title: _nullableString(json['title']),
      body: _nullableString(json['body']),
      data: _mapFrom(json['data'] ?? json),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
