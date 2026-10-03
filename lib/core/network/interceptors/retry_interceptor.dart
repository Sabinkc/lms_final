import 'package:dio/dio.dart';

/// Retries a GET once when the connection itself failed — the brief drops
/// school Wi-Fi and mobile data have, which otherwise put a "Network error"
/// screen in front of the user for a request that would succeed a second
/// later. Only GETs (reads, safe to repeat); a POST/PATCH/DELETE is never
/// replayed, so nothing can be saved, approved or deleted twice. A receive
/// timeout is not retried either: the server got the request and is slow, and
/// waiting another 15 s would be worse than showing the error.
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final Duration delay;

  static const _retriedKey = 'retried';

  RetryInterceptor(this._dio, {this.delay = const Duration(seconds: 1)});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (options.method.toUpperCase() != 'GET' || options.extra[_retriedKey] == true || !_isConnectionFailure(err)) {
      return handler.next(err);
    }
    await Future<void>.delayed(delay);
    try {
      final response = await _dio.fetch<dynamic>(options..extra[_retriedKey] = true);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static bool _isConnectionFailure(DioException err) =>
      err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout;
}
