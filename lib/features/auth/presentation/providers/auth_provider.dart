import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/app_role.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds session state and is read by `AppRouter`'s redirect logic for
/// role-based guarding (docs/architecture.md §3, §4) — the one deliberate
/// exception to "widgets read state via Provider": the router reads this
/// through the service locator directly (see `core/router/app_router.dart`
/// for why), not via `context.watch`.
///
/// This is a **feature** provider, not a global one — it holds only
/// session/role state. Every other feature gets its own
/// `ChangeNotifier` for its own slice of state; none of them merge into
/// this class or into any single app-wide provider.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository) {
    _restore();
  }

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  AppException? _lastError;
  bool _isSubmitting = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  AppRole? get role => _user?.role;
  AppException? get lastError => _lastError;
  bool get isSubmitting => _isSubmitting;

  Future<void> _restore() async {
    final session = await _repository.restoreSession();
    _user = session?.user;
    _status = session != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    final result = await _repository.login(email: email, password: password);

    result.when(
      success: (session) {
        _user = session.user;
        _status = AuthStatus.authenticated;
      },
      failure: (error) {
        _lastError = error;
        _status = AuthStatus.unauthenticated;
      },
    );

    _isSubmitting = false;
    notifyListeners();
  }

  /// Called after the user saves My Profile, so the header initials and the
  /// More screen's profile card pick up a new name/email straight away.
  Future<void> updateIdentity({required String fullName, required String email}) async {
    final current = _user;
    if (current == null) return;
    _user = AppUser(id: current.id, fullName: fullName, email: email, role: current.role);
    notifyListeners();
    await _repository.cacheUser(_user!);
  }

  Future<void> logout() async {
    final session = await _repository.restoreSession();
    await _repository.logout(session?.refreshToken ?? '');
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
