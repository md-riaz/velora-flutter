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
    String successKey = 'success',
    String dataKey = 'data',
    String messageKey = 'message',
    String errorsKey = 'errors',
  }) {
    if (json is Map<String, dynamic>) {
      final rawData = json.containsKey(dataKey) ? json[dataKey] : json;
      return ApiResponse<T>(
        success: json[successKey] is bool ? json[successKey] as bool : true,
        data: parser == null ? rawData as T? : parser(rawData),
        message: json[messageKey] as String?,
        errors: _parseErrors(json[errorsKey]),
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
