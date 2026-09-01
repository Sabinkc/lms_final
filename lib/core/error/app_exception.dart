/// Typed exception hierarchy every repository throws into / every provider
/// catches from — never a raw [DioException] or [FormatException] crosses
/// out of `core/network` or `core/storage`.
///
/// See docs/architecture.md §8 and docs/api_spec.md §2: the backend's
/// response/error envelope is confirmed **not uniform** (most endpoints
/// return `{success, message, data}`, some a bare `{message}`, at least one
/// `{error}`), and the 401 shape differs by which backend middleware
/// rejected the request (`protect` returns a `code`, `protectAdmin` does
/// not). [ErrorMapper] is the one place that reads those shapes; everywhere
/// else in the app only ever sees the types below.
sealed class AppException implements Exception {
  final String message;

  /// Machine-readable code when the backend supplied one (e.g.
  /// `TOKEN_EXPIRED`, `NO_TOKEN`, `SUBSCRIPTION_INACTIVE`). `null` when the
  /// rejecting middleware didn't include one — callers must not assume this
  /// is always present (docs/api_spec.md §2).
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// No connectivity, timeout, DNS failure, socket error — nothing was ever
/// heard back from the server.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error. Please check your connection.']);
}

/// 401. Central handling per docs/architecture.md §8: attempt one token
/// refresh if [code] is `TOKEN_EXPIRED`; otherwise fall through to the
/// silent-logout path. `code` may be absent (routes guarded by
/// `protectAdmin` return none) — treat absence as "not recoverable, log out".
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    String message = 'Session expired. Please log in again.',
    String? code,
  ]) : super(message, code: code);
}

/// 403. Distinct from [UnauthorizedException] — the caller *is*
/// authenticated but the role/subscription/permission check failed (e.g.
/// `SCHOOL_DEACTIVATED`, `SUBSCRIPTION_INACTIVE` per docs/api_spec.md §2).
final class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = 'You do not have permission to do that.',
    String? code,
  ]) : super(message, code: code);
}

/// 400 / 422 with field-level validation errors.
final class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;
  const ValidationException(super.message, {this.fieldErrors = const {}, super.code});
}

/// 404.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.']);
}

/// 5xx, or a 2xx with a response shape that couldn't be parsed at all.
final class ServerException extends AppException {
  const ServerException([
    String message = 'Something went wrong on our end. Please try again.',
    String? code,
  ]) : super(message, code: code);
}

/// Anything that doesn't fit the above — a genuine catch-all, never the
/// first thing reached for.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
