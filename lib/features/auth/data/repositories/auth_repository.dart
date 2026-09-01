import '../../../../core/error/result.dart';
import '../models/auth_session.dart';

/// Presentation code (specifically `AuthProvider`) depends only on this
/// interface — never on `AuthRepositoryHttp` or `ApiClient`/`Dio` directly.
/// `service_locator.dart` is the only place that constructs the concrete
/// implementation (docs/architecture.md §1, §5).
///
/// Scope note: only session bootstrapping (login/logout/refresh/restore)
/// is modeled here. Registration, OTP email-verification, forgot-password,
/// and the separate PIN-reset flow (all confirmed real endpoints per
/// docs/api_spec.md §4.1) are Auth **feature** work — deliberately left out
/// of this foundation pass.
abstract class AuthRepository {
  Future<Result<AuthSession>> login({required String email, required String password});

  Future<Result<AuthSession>> refreshToken(String refreshToken);

  Future<Result<void>> logout(String refreshToken);

  /// Reads whatever session is currently persisted (secure storage token,
  /// or — for the mock — an in-memory flag) without making a network call.
  /// Used by `SplashScreen` to decide Login vs. a role Dashboard.
  Future<AuthSession?> restoreSession();
}
