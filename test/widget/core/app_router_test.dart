import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/router/app_router.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_lms/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _adminSession = AuthSession(
  user: AppUser(id: 'admin-1', fullName: 'Demo Admin', email: 'admin@test.com', role: AppRole.admin),
  accessToken: 'access',
  refreshToken: 'refresh',
);

/// Mirrors `app.dart`'s actual provider wiring (`AuthProvider` exposed via
/// `ChangeNotifierProvider`, the router built by reading it back out of
/// context) rather than passing `authProvider` straight to
/// `buildAppRouter` — `SplashScreen`/`LoginScreen`/`PlaceholderScreen` all
/// read it via `context.watch`/`context.read`, same as in the real app.
/// (`RoleHomeScreen` replaced `PlaceholderScreen` for the 4 dashboards —
/// `PlaceholderScreen` itself is only used for `/unauthorized` now.)
Widget _appWith(AuthProvider authProvider) => ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: Builder(
        builder: (context) => MaterialApp.router(routerConfig: buildAppRouter(context.read<AuthProvider>())),
      ),
    );

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  /// Regression test for the bug this exact scenario surfaced live (real
  /// app run, not just a unit test of `_redirect` in isolation): splash was
  /// bundled into the same "already a valid resting place" check as login
  /// for `AuthStatus.unauthenticated`, so a freshly restored, logged-out
  /// session never left the splash/loading screen at all.
  testWidgets('a fresh unauthenticated session (restoreSession -> null) leaves splash and lands on login',
      (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider));
    // Let restoreSession()'s Future resolve and the router react to it.
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a restored authenticated session leaves splash and lands on that role\'s home', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _adminSession);
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Admin Dashboard'), findsOneWidget);
  });

  testWidgets('login() success navigates from the login screen to that role\'s home', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Result.success(_adminSession));
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await authProvider.login(email: 'admin@test.com', password: 'secret');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Admin Dashboard'), findsOneWidget);
  });

  testWidgets('logout() from a dashboard returns to the login screen', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _adminSession);
    when(() => repository.logout(any())).thenAnswer((_) async => const Result.success(null));
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Admin Dashboard'), findsOneWidget);

    // The dashboard's logout action is an icon button (tooltip 'Log out'),
    // not a labeled button — see `RoleHomeScreen`.
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
