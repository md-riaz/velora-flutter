import 'dart:math' as math;

import 'api_exception.dart';
import 'api_response.dart';

/// Lightweight mock helper for data sources that don't have a real backend yet.
///
/// Simulates realistic network latency so UI loading states are exercised
/// during development. Designed to be swapped with real API calls without
/// changing the repository interface.
///
/// Usage in a mock data source:
/// ```dart
/// class MockPostsDataSource implements PostsDataSource {
///   @override
///   Future<List<PostModel>> index() async {
///     return VeloraMockApi.ok(
///       _mockPosts.map((m) => m.toJson()).toList(),
///       parser: (v) => (v as List).map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList(),
///     );
///   }
/// }
/// ```
class VeloraMockApi {
  static final math.Random _rng = math.Random();

  static const int _defaultDelayMs = 350;
  static const int _jitterMs = 200;

  /// Returns a successful [ApiResponse] after a simulated network delay.
  ///
  /// [body] should be JSON-compatible (Map, List, String, etc.).
  /// [parser] converts the raw JSON body to [T] — identical to the real API call.
  static Future<T> ok<T>(
    Object? body, {
    T Function(Object?)? parser,
    int delayMs = _defaultDelayMs,
  }) async {
    await _delay(delayMs);
    final response = ApiResponse<T>.fromJson(
      body,
      statusCode: 200,
      parser: parser,
    );
    if (response.data == null && null is! T) {
      throw ApiException(message: 'Mock: parser returned null for $T');
    }
    return response.data as T;
  }

  /// Returns a [PaginatedData]-shaped response — the standard Laravel
  /// pagination envelope used by [PaginatedData.fromJson].
  ///
  /// [items] is the raw list. [page] / [perPage] / [total] are used to build
  /// the meta block.
  static Future<Map<String, dynamic>> paginated(
    List<Object?> items, {
    int page = 1,
    int perPage = 15,
    int? total,
    int delayMs = _defaultDelayMs,
  }) async {
    await _delay(delayMs);
    final tot = total ?? items.length;
    final limit = perPage < 1 ? 1 : perPage;
    final lastPage = (tot / limit).ceil().clamp(1, 999999);
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, items.length);
    final pageItems = items.sublist(
      start.clamp(0, items.length),
      end,
    );
    return {
      'data': pageItems,
      'meta': {
        'current_page': page,
        'last_page': lastPage,
        'per_page': perPage,
        'total': tot,
      },
    };
  }

  /// Simulates a server error.  Throws [ApiException] after a short delay.
  static Future<T> fail<T>({
    String message = 'Simulated server error',
    int statusCode = 500,
    int delayMs = 200,
  }) async {
    await _delay(delayMs);
    throw ApiException(message: message, statusCode: statusCode);
  }

  static Future<void> _delay(int baseMs) =>
      Future<void>.delayed(Duration(milliseconds: baseMs + _rng.nextInt(_jitterMs)));
}
