class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors = const {},
  });

  @override
  String toString() => message;
}
