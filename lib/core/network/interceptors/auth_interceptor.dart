import 'package:dio/dio.dart';

import '../../storage/secure_storage_service.dart';

/// Attaches the confirmed real auth transport (docs/api_spec.md §2):
/// `Authorization: Bearer <token>` header on every request, with the
/// backend's documented `?token=` query-param fallback for download-style
/// GET requests that can't set headers (ID cards, some document links, via
/// the backend's own `tokenFromQuery` middleware) — set
/// `options.extra['useQueryToken'] = true` on a request to opt into that
/// fallback instead of the header.
///
/// Token *refresh* is deliberately NOT handled here — see
/// `ApiClient`'s doc comment for why that lives one layer up.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.readAccessToken();

    if (token != null && token.isNotEmpty) {
      final useQueryToken = options.extra['useQueryToken'] == true;
      if (useQueryToken) {
        options.queryParameters['token'] = token;
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}
