import 'app_user.dart';

/// Shape returned by the confirmed `POST /api/auth/login` and
/// `POST /api/auth/refresh` endpoints (docs/api_spec.md §2): `token` +
/// `refreshToken` + `role` + `data` (the user object). Both real endpoints
/// return this same shape, so one model covers both.
class AuthSession {
  final AppUser user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AppUser.fromJson(json['data'] as Map<String, dynamic>),
        accessToken: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}
