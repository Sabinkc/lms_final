import 'package:dio/dio.dart';

import '../../storage/secure_storage_service.dart';

/// Handles the confirmed `POST /api/auth/refresh` contract
/// (docs/api_spec.md §2) on a 401 whose body carries `code: "TOKEN_EXPIRED"`
/// — the one case [AppException]'s docs promise is refresh-recoverable.
/// Any other 401 (including every `protectAdmin`-guarded route, which never
/// sends a `code` at all — docs/api_spec.md §2) falls straight through
/// un-retried, same as before this interceptor existed.
///
/// Single-flight by construction: concurrent 401s share one in-flight
/// `_refresh` future instead of each firing their own `/auth/refresh` call
/// (docs/production_roadmap.md Phase A step 3) — the `??=` below is safe
/// because nothing awaits between it and the assignment, so two calls
/// arriving back-to-back on the same event-loop turn still only start one
/// refresh.
///
/// Uses its own bare [Dio] for the refresh call itself (same base URL, same
/// underlying [HttpClientAdapter] — so it's still real HTTP / still
/// fake-adapter-testable, just without interceptors) rather than the app's
/// shared [Dio] with interceptors attached — reusing the interceptor-laden
/// one would re-enter this same interceptor if the refresh call ever itself
/// 401'd, and the refresh call needs no `Authorization` header anyway (the
/// refresh token travels in the body, per the confirmed contract).
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final Dio _refreshDio;
  final SecureStorageService _secureStorage;

  TokenRefreshInterceptor({
    required Dio dio,
    required SecureStorageService secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _refreshDio = (Dio(BaseOptions(baseUrl: dio.options.baseUrl, contentType: 'application/json'))
          ..httpClientAdapter = dio.httpClientAdapter);

  Future<String>? _inFlightRefresh;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response?.statusCode != 401 || _extractCode(response?.data) != 'TOKEN_EXPIRED') {
      return handler.next(err);
    }

    try {
      final newAccessToken = await (_inFlightRefresh ??= _refresh());
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh token itself is gone/invalid — nothing left to retry with.
      // Drop the now-useless tokens so the next `restoreSession()` reports
      // unauthenticated instead of retrying forever on a dead refresh token.
      await _secureStorage.clearTokens();
      return handler.next(err);
    }
  }

  Future<String> _refresh() async {
    try {
      final refreshToken = await _secureStorage.readRefreshToken();
      if (refreshToken == null) throw StateError('No refresh token to refresh with.');

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      final newAccessToken = data['token'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await _secureStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return newAccessToken;
    } finally {
      _inFlightRefresh = null;
    }
  }

  String? _extractCode(Object? body) {
    if (body is Map) {
      final code = body['code'];
      if (code is String) return code;
    }
    return null;
  }
}
