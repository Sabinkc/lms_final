import 'package:cloud_lms/core/router/role_shell.dart';
import 'package:cloud_lms/core/theme/app_theme.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/more_screen.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/role_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Real per-role dashboard chrome (`RoleShell` + `RoleHomeScreen`/
/// `MoreScreen`, built in the 2026-09-01 UI modernization pass) is the one
/// surface where the whole point — per-role accent color differentiation
/// via `AppColors.roleColor` — is only actually visible on screen, not
/// provable from a unit test. Golden coverage here is what
/// `docs/production_roadmap.md` flagged as still missing ("only existing
/// goldens were regenerated, not expanded").
///
/// Mirrors `app_router.dart`'s real `StatefulShellRoute.indexedStack`
/// shape (4 branches: Home, 2 promoted tabs, More) but with inert
/// placeholders for the 2 middle tabs — those are existing, separately
/// tested feature screens with their own provider wiring; only the shell
/// chrome + Home/More (this pass's actual new code) are under test here.
Future<void> _pumpDashboard(
  WidgetTester tester, {
  required AppRole role,
  required Brightness brightness,
  required String initialLocation,
}) async {
  final view = tester.view;
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });
  view.devicePixelRatio = 1.0;
  view.physicalSize = const Size(390, 844);

  final authRepository = _MockAuthRepository();
  when(() => authRepository.restoreSession()).thenAnswer(
    (_) async => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Jamie Rivera', email: 'jamie@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    ),
  );
  final authProvider = AuthProvider(authRepository);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: role, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => RoleHomeScreen(role: role))]),
          StatefulShellBranch(routes: [GoRoute(path: '/tab1', builder: (context, state) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tab2', builder: (context, state) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (context, state) => MoreScreen(role: role))]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp.router(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final role in AppRole.values) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final suffix = brightness == Brightness.light ? 'light' : 'dark';

      testWidgets('${role.name} Home dashboard ($suffix)', (tester) async {
        await _pumpDashboard(tester, role: role, brightness: brightness, initialLocation: '/home');
        await expectLater(find.byType(RoleShell), matchesGoldenFile('goldens/dashboard_${role.name}_home_$suffix.png'));
      });

      testWidgets('${role.name} More screen ($suffix)', (tester) async {
        await _pumpDashboard(tester, role: role, brightness: brightness, initialLocation: '/more');
        await expectLater(find.byType(RoleShell), matchesGoldenFile('goldens/dashboard_${role.name}_more_$suffix.png'));
      });
    }
  }
}
