import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Request/response logging routed through [AppLogger] (never `print`), so
/// it respects [EnvConfig.enableLogging] and is automatically silent in a
/// prod build regardless of what a developer forgets to remove.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.warning(
      '✕ ${err.requestOptions.method} ${err.requestOptions.uri} '
      '(${err.response?.statusCode ?? err.type.name})',
    );
    handler.next(err);
  }
}
