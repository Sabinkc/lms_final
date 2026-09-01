import 'package:dio/dio.dart';

import 'app_exception.dart';

/// The one place in the app that reads a raw [DioException] / raw response
/// body. Everything downstream (repositories, providers, widgets) only ever
/// sees [AppException].
///
/// Deliberately defensive per docs/api_spec.md §2 and docs/architecture.md
/// §8: the backend's envelope is confirmed **not uniform** — most endpoints
/// return `{success, message, data}`, some a bare `{message}`, at least one
/// debug endpoint `{error}` instead of `message`. This mapper checks for
/// `message`/`error` presence rather than assuming `success` is always
/// there, and never assumes a `code` field exists on a 401 (`protectAdmin`-
/// guarded routes omit it — see [AppException.code]'s doc comment).
class ErrorMapper {
  const ErrorMapper();

  AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is DioException) return _mapDioException(error);

    return const UnknownException();
  }

  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const UnknownException('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('Could not establish a secure connection.');
      case DioExceptionType.badResponse:
        return _mapResponse(error);
      case DioExceptionType.unknown:
        return const NetworkException();
    }
  }

  AppException _mapResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final body = error.response?.data;
    final message = _extractMessage(body);
    final code = _extractCode(body);

    return switch (statusCode) {
      401 => UnauthorizedException(message ?? 'Session expired. Please log in again.', code),
      403 => ForbiddenException(message ?? 'You do not have permission to do that.', code),
      404 => NotFoundException(message ?? 'Not found.'),
      400 || 422 => ValidationException(
          message ?? 'Please check your input and try again.',
          fieldErrors: _extractFieldErrors(body),
          code: code,
        ),
      >= 500 => ServerException(message ?? 'Something went wrong on our end. Please try again.', code),
      _ => ServerException(message ?? 'Unexpected response (status $statusCode).', code),
    };
  }

  /// Checks `message` first (the common case), then `error` (the one
  /// debug-only backend endpoint confirmed to use it — docs/api_spec.md §2)
  /// — never assumes either is present.
  String? _extractMessage(Object? body) {
    if (body is Map) {
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = body['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return null;
  }

  /// `code` is only ever present on responses from the `protect` middleware
  /// (`NO_TOKEN` / `TOKEN_EXPIRED` / `TOKEN_INVALID`, plus a few
  /// account-state codes like `SCHOOL_DEACTIVATED`). `protectAdmin`-guarded
  /// routes never include it — callers must treat `null` as "unknown, not
  /// necessarily recoverable", never as an error condition on its own.
  String? _extractCode(Object? body) {
    if (body is Map) {
      final code = body['code'];
      if (code is String && code.isNotEmpty) return code;
    }
    return null;
  }

  Map<String, List<String>> _extractFieldErrors(Object? body) {
    if (body is Map && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      return errors.map((key, value) {
        final list = value is List ? value.map((e) => e.toString()).toList() : [value.toString()];
        return MapEntry(key.toString(), list);
      });
    }
    return const {};
  }
}
