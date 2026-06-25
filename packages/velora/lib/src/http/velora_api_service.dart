import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../config/velora_config.dart';
import '../storage/velora_storage_service.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'velora_api_interceptor.dart';

class VeloraApiService extends GetxService {
  final VeloraConfig config;
  final VeloraStorageService storage;
  late final Dio dio;
  CancelToken _userCancelToken = CancelToken();

  VeloraApiService({
    required this.config,
    required this.storage,
    List<VeloraApiInterceptor> interceptors = const [],
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        headers: const {'Accept': 'application/json'},
      ),
    );
    // Built-in auth token injector (always first).
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    for (final interceptor in interceptors) {
      addInterceptor(interceptor);
    }
  }

  /// Add a [VeloraApiInterceptor] at runtime.
  ///
  /// Interceptors are called in the order they were added, after the
  /// built-in auth token injector.
  void addInterceptor(VeloraApiInterceptor interceptor) {
    interceptor.onAttach(dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: interceptor.onRequest,
        onResponse: interceptor.onResponse,
        onError: interceptor.onError,
      ),
    );
  }

  void cancelUserScope([String reason = 'User session ended.']) {
    _userCancelToken.cancel(reason);
    _userCancelToken = CancelToken();
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? value)? parser,
    bool userScoped = true,
  }) {
    return _send<T>(
      () => dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: userScoped ? _userCancelToken : null,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    T Function(Object? value)? parser,
    bool userScoped = true,
  }) {
    return _send<T>(
      () => dio.post<Object?>(
        path,
        data: data,
        cancelToken: userScoped ? _userCancelToken : null,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    T Function(Object? value)? parser,
    bool userScoped = true,
  }) {
    return _send<T>(
      () => dio.put<Object?>(
        path,
        data: data,
        cancelToken: userScoped ? _userCancelToken : null,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    T Function(Object? value)? parser,
    bool userScoped = true,
  }) {
    return _send<T>(
      () => dio.patch<Object?>(
        path,
        data: data,
        cancelToken: userScoped ? _userCancelToken : null,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    T Function(Object? value)? parser,
    bool userScoped = true,
  }) {
    return _send<T>(
      () => dio.delete<Object?>(
        path,
        data: data,
        cancelToken: userScoped ? _userCancelToken : null,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? value)? parser,
  ) async {
    try {
      final response = await request();
      final r = config.response;
      return ApiResponse<T>.fromJson(
        response.data,
        statusCode: response.statusCode,
        parser: parser,
        successKey: r.successKey,
        dataKey: r.dataKey,
        messageKey: r.messageKey,
        errorsKey: r.errorsKey,
      );
    } on DioException catch (error) {
      throw _normalize(error);
    }
  }

  ApiException _normalize(DioException error) {
    final response = error.response;
    final data = response?.data;
    final r = config.response;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data[r.messageKey]?.toString() ??
            error.message ??
            'Request failed',
        statusCode: response?.statusCode,
        errors: ApiResponse<Object?>.fromJson(
          data,
          messageKey: r.messageKey,
          errorsKey: r.errorsKey,
        ).errors,
      );
    }
    return ApiException(
      message: error.message ?? 'Request failed',
      statusCode: response?.statusCode,
    );
  }
}
