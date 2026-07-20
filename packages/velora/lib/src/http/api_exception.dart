class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  /// `true` when this exception was normalized from a connection-level
  /// `DioException` -- the request never reached the server at all (DNS /
  /// connect failure, unreachable host, or a connect/send/receive timeout)
  /// -- as opposed to a well-formed HTTP error response (e.g. a 404/500,
  /// which *did* reach the server) or any other normalized `DioException`.
  ///
  /// [VeloraApiService] sets this from the originating `DioException`'s
  /// `DioExceptionType` before that type information would otherwise be
  /// discarded. Callers that need to distinguish "offline" from "server
  /// said no" (e.g. `velora_db`'s cache-fallback logic) should key off this
  /// flag rather than re-deriving it from `statusCode == null`, which is
  /// also true for other, unrelated normalized errors (e.g. a cancelled
  /// request).
  final bool isConnectionError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors = const {},
    this.isConnectionError = false,
  });

  @override
  String toString() => message;
}
