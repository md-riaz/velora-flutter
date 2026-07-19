/// An immutable record of a write request queued while the device was
/// offline (or the server was unreachable), to be replayed once connectivity
/// is restored.
class OfflineRequest {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const OfflineRequest({
    required this.id,
    required this.method,
    required this.path,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OfflineRequest.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return OfflineRequest(
      id: json['id']?.toString() ?? '',
      method: json['method']?.toString() ?? 'POST',
      path: json['path']?.toString() ?? '',
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
