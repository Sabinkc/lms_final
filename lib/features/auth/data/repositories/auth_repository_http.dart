import 'dart:convert';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_prefs_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'auth_repository.dart';

/// Real implementation against the confirmed backend contract
/// (docs/api_spec.md §4.1: `POST /api/auth/login`, `/refresh`, `/logout`
/// all live, public, JSON-body endpoints). Wired up in
/// `service_locator.dart` as of docs/production_roadmap.md Phase A.
///
/// Only wraps the three session endpoints on purpose: registration, OTP
/// verification, forgot-password, and the separate PIN-reset flow are
/// real confirmed endpoints too, but they're Auth **feature** work (forms,
/// validation UX, resend-cooldown timers), not foundation plumbing.
class AuthRepositoryHttp implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalPrefsService _localPrefs;

  AuthRepositoryHttp(this._apiClient, this._secureStorage, this._localPrefs);

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) async {
    try {
      final session = await _apiClient.post<AuthSession>(
        '/auth/login',
        data: {'email': email, 'password': password},
        parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
      );
      await _persistSession(session);
      return Result.success(session);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AuthSession>> refreshToken(String refreshToken) async {
    try {
      final session = await _apiClient.post<AuthSession>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
      );
      await _persistSession(session);
      return Result.success(session);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> logout(String refreshToken) async {
    try {
      await _apiClient.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
      await _clearSession();
      return const Result.success(null);
    } on AppException catch (e) {
      // Backend session is best-effort here — still clear the local
      // session so the user isn't stuck logged in on-device.
      await _clearSession();
      return Result.failure(e);
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    // No confirmed "get current session" endpoint exists (docs/api_spec.md
    // §11) — restoring is local-only: trust the user fields cached at login
    // time (see `LocalPrefsService.cachedUserJson`) alongside the still-
    // present tokens, rather than re-fetching a profile. If tokens exist but
    // the cached identity is somehow missing (e.g. app data partially
    // cleared), there's nothing to reconstruct a session from — drop the
    // now-orphaned tokens too instead of leaving them stranded.
    final token = await _secureStorage.readAccessToken();
    final refresh = await _secureStorage.readRefreshToken();
    if (token == null || refresh == null) return null;

    final cachedUserJson = _localPrefs.cachedUserJson;
    if (cachedUserJson == null) {
      await _secureStorage.clearTokens();
      return null;
    }

    final user = AppUser.fromJson(jsonDecode(cachedUserJson) as Map<String, dynamic>);
    return AuthSession(user: user, accessToken: token, refreshToken: refresh);
  }

  @override
  Future<void> cacheUser(AppUser user) => _localPrefs.setCachedUserJson(jsonEncode(user.toJson()));

  Future<void> _persistSession(AuthSession session) async {
    await _secureStorage.saveTokens(accessToken: session.accessToken, refreshToken: session.refreshToken);
    await _localPrefs.setCachedUserJson(jsonEncode(session.user.toJson()));
  }

  Future<void> _clearSession() async {
    await _secureStorage.clearTokens();
    await _localPrefs.clearCachedUser();
  }
}
