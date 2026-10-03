import 'package:dio/dio.dart';

import '../config/env.dart';
import '../error/app_exception.dart';
import '../error/error_mapper.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

/// The single shared HTTP client. No `*_repository_http.dart` should ever
/// construct its own [Dio] instance — always take an [ApiClient] as a
/// constructor dependency (wired by `service_locator.dart`), so auth-header
/// injection, timeouts, and error mapping stay centralized in one place
/// (docs/architecture.md §6).
///
/// Every method returns already-mapped to [AppException] on failure — a
/// repository's `try { ... } on AppException catch (e) { return
/// Result.failure(e); }` is all the error handling it should ever need to
/// write; it should never see a raw [DioException].
///
/// Token *refresh-on-401* is handled transparently by
/// [TokenRefreshInterceptor] (docs/production_roadmap.md Phase A step 3) —
/// a caller of `get`/`post`/etc. never sees the 401 at all when a refresh
/// successfully recovers it; the retried response comes back as if the
/// first request had simply succeeded. Only an unrecoverable 401 (refresh
/// itself fails, or the backend didn't send `code: "TOKEN_EXPIRED"` at all —
/// true for every `protectAdmin`-guarded route per docs/api_spec.md §2)
/// reaches [ErrorMapper] and surfaces as [UnauthorizedException].
class ApiClient {
  final Dio _dio;
  final ErrorMapper _errorMapper;

  ApiClient({
    required EnvConfig env,
    required SecureStorageService secureStorage,
    Dio? dio,
    ErrorMapper errorMapper = const ErrorMapper(),
  })  : _dio = dio ?? Dio(),
        _errorMapper = errorMapper {
    _dio.options = BaseOptions(
      baseUrl: '${env.baseUrl}${EnvConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    );

    _dio.interceptors.add(AuthInterceptor(secureStorage));
    _dio.interceptors.add(TokenRefreshInterceptor(dio: _dio, secureStorage: secureStorage));
    _dio.interceptors.add(RetryInterceptor(_dio));
    if (env.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Escape hatch for the rare call site that needs raw Dio (e.g. a future
  /// multipart file upload with progress callbacks) without duplicating
  /// base-URL/auth/logging setup.
  Dio get raw => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parse,
  }) =>
      _request(() => _dio.get(path, queryParameters: queryParameters, options: options), parse);

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parse,
  }) =>
      _request(
        () => _dio.post(path, data: data, queryParameters: queryParameters, options: options),
        parse,
      );

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parse,
  }) =>
      _request(
        () => _dio.put(path, data: data, queryParameters: queryParameters, options: options),
        parse,
      );

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parse,
  }) =>
      _request(
        () => _dio.patch(path, data: data, queryParameters: queryParameters, options: options),
        parse,
      );

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parse,
  }) =>
      _request(
        () => _dio.delete(path, data: data, queryParameters: queryParameters, options: options),
        parse,
      );

  Future<T> _request<T>(
    Future<Response> Function() call,
    T Function(dynamic data)? parse,
  ) async {
    try {
      final response = await call();
      final data = response.data;
      if (parse != null) return parse(data);
      return data as T;
    } catch (error, stackTrace) {
      throw _errorMapper.map(error, stackTrace);
    }
  }
}
