import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Base class for Velora HTTP interceptors. Override only the methods you need;
/// the defaults pass everything through unchanged.
///
/// Register interceptors at boot time:
/// ```dart
/// await Velora.boot(
///   config: config,
///   interceptors: [VeloraLogInterceptor(), VeloraRetryInterceptor()],
/// );
/// ```
///
/// Or add them at runtime:
/// ```dart
/// Velora.api.addInterceptor(MyCustomInterceptor());
/// ```
abstract class VeloraApiInterceptor {
  const VeloraApiInterceptor();

  /// Called once when the interceptor is attached to a [Dio] instance.
  /// Override to capture the [Dio] reference (e.g. for retry logic).
  // ignore: use_setters_to_change_properties
  void onAttach(Dio dio) {}

  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.next(options);

  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) =>
      handler.next(response);

  void onError(DioException err, ErrorInterceptorHandler handler) =>
      handler.next(err);
}

// ---------------------------------------------------------------------------

/// Pretty-prints every request and response to the console.
///
/// Recommended for debug builds only:
/// ```dart
/// if (kDebugMode) interceptors.add(VeloraLogInterceptor()),
/// ```
class VeloraLogInterceptor extends VeloraApiInterceptor {
  final Logger _log;

  VeloraLogInterceptor({Logger? logger})
      : _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log.d('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e(
      '✗ ${err.requestOptions.method} ${err.requestOptions.path}',
      error: err.message,
    );
    handler.next(err);
  }
}

// ---------------------------------------------------------------------------

/// Retries failed requests on network / timeout errors.
///
/// Only retries connection-level failures (no server response). Errors with a
/// server response (4xx, 5xx) are passed through immediately.
///
/// ```dart
/// VeloraRetryInterceptor(maxAttempts: 3, delay: Duration(seconds: 2))
/// ```
class VeloraRetryInterceptor extends VeloraApiInterceptor {
  final int maxAttempts;
  final Duration delay;
  late Dio _dio;

  VeloraRetryInterceptor({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
  });

  @override
  void onAttach(Dio dio) => _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryable = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (!isRetryable) {
      handler.next(err);
      return;
    }

    final attempts = (err.requestOptions.extra['_velora_retry'] as int?) ?? 0;
    if (attempts >= maxAttempts) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(delay * (attempts + 1));
    err.requestOptions.extra['_velora_retry'] = attempts + 1;

    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }
}
