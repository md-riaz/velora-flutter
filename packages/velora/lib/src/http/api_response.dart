class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, List<String>> errors;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors = const {},
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Object? json, {
    int? statusCode,
    T Function(Object? value)? parser,
  }) {
    if (json is Map<String, dynamic>) {
      final rawData = json.containsKey('data') ? json['data'] : json;
      return ApiResponse<T>(
        success: json['success'] is bool ? json['success'] as bool : true,
        data: parser == null ? rawData as T? : parser(rawData),
        message: json['message'] as String?,
        errors: _parseErrors(json['errors']),
        statusCode: statusCode,
      );
    }

    return ApiResponse<T>(
      success: true,
      data: parser == null ? json as T? : parser(json),
      statusCode: statusCode,
    );
  }

  static Map<String, List<String>> _parseErrors(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, entry) {
      final messages = entry is List
          ? entry.map((item) => item.toString()).toList(growable: false)
          : <String>[entry.toString()];
      return MapEntry(key.toString(), messages);
    });
  }
}
