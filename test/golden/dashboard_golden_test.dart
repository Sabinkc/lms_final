import 'package:cloud_lms/core/router/role_shell.dart';
import 'package:cloud_lms/core/storage/local_prefs_service.dart';
import 'package:cloud_lms/core/theme/app_theme.dart';
import 'package:cloud_lms/core/theme/theme_controller.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/dashboard/data/models/admin_dashboard_overview.dart';
import 'package:cloud_lms/features/dashboard/data/repositories/admin_dashboard_repository.dart';
import 'package:cloud_lms/features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/more_screen.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAdminDashboardRepository extends Mock implements AdminDashboardRepository {}

class _MockNotificationRepository extends Mock implements NotificationRepository {}

const _emptyStats = AdminDashboardStats(
  totalStudents: 0,
  studentsChangePercent: 0,
  totalTeachers: 0,
  pendingFeesCount: 0,
  attendanceRatePercent: 0,
  attendanceChangePercent: 0,
);

/// Real per-role `RoleShell` + `MoreScreen` chrome (built in the 2026-09-01
/// UI modernization pass) is the one surface where the whole point —
/// per-role accent color differentiation via `AppColors.roleColor` — is
/// only actually visible on screen, not provable from a unit test.
///
/// Mirrors `app_router.dart`'s real `StatefulShellRoute.indexedStack`
/// shape (4 branches: Home, 2 promoted tabs, More) but with inert
/// placeholders for the Home and 2 middle tabs — Home golden coverage was
/// dropped 2026-09-28 when each role got its own dedicated, heavily
/// provider-dependent Home screen (`AdminHomeScreen`/`TeacherHomeScreen`/
/// `StudentHomeScreen`/`ParentHomeScreen`, replacing the shared
/// `RoleHomeScreen` this test used to build directly); giving each of those
/// real per-role provider mocks is a separate, larger task than this pass.
/// Only the shell chrome + More (still real, unchanged) are under test here.
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

  final dashboardRepository = _MockAdminDashboardRepository();
  when(() => dashboardRepository.getStats()).thenAnswer((_) async => const Result.success(_emptyStats));
  when(() => dashboardRepository.getUpcomingExams(limit: any(named: 'limit')))
      .thenAnswer((_) async => const Result.success(<UpcomingExamSummary>[]));

  final notificationRepository = _MockNotificationRepository();
  when(() => notificationRepository.getNotifications(limit: any(named: 'limit'), unreadOnly: any(named: 'unreadOnly')))
      .thenAnswer((_) async => const Result.success((0, <AppNotification>[])));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: role, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tab1', builder: (context, state) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/tab2', builder: (context, state) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (context, state) => MoreScreen(role: role))]),
        ],
      ),
    ],
  );

  SharedPreferences.setMockInitialValues({});
  final prefs = LocalPrefsService(await SharedPreferences.getInstance());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AdminDashboardProvider>(create: (_) => AdminDashboardProvider(dashboardRepository)),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider(notificationRepository)),
      ],
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

      testWidgets('${role.name} More screen ($suffix)', (tester) async {
        await _pumpDashboard(tester, role: role, brightness: brightness, initialLocation: '/more');
        await expectLater(find.byType(RoleShell), matchesGoldenFile('goldens/dashboard_${role.name}_more_$suffix.png'));
      });
    }
  }
}
