import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/router/app_router.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/auth/presentation/screens/login_screen.dart';
import 'package:cloud_lms/features/auth/presentation/screens/splash_screen.dart';
import 'package:cloud_lms/features/dashboard/data/models/admin_dashboard_overview.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/admin_home_screen.dart';
import 'package:cloud_lms/features/dashboard/data/repositories/admin_dashboard_repository.dart';
import 'package:cloud_lms/features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAdminDashboardRepository extends Mock implements AdminDashboardRepository {}

class _MockNotificationRepository extends Mock implements NotificationRepository {}

const _adminSession = AuthSession(
  user: AppUser(id: 'admin-1', fullName: 'Demo Admin', email: 'admin@test.com', role: AppRole.admin),
  accessToken: 'access',
  refreshToken: 'refresh',
);

const _emptyStats = AdminDashboardStats(
  totalStudents: 0,
  studentsChangePercent: 0,
  totalTeachers: 0,
  pendingFeesCount: 0,
  attendanceRatePercent: 0,
  attendanceChangePercent: 0,
);

/// Mirrors `app.dart`'s actual provider wiring (`AuthProvider` exposed via
/// `ChangeNotifierProvider`, the router built by reading it back out of
/// context) rather than passing `authProvider` straight to
/// `buildAppRouter` — `SplashScreen`/`LoginScreen`/`PlaceholderScreen` all
/// read it via `context.watch`/`context.read`, same as in the real app.
/// (Each role now has its own dedicated Home screen — `AdminHomeScreen`,
/// `TeacherHomeScreen`, `StudentHomeScreen`, `ParentHomeScreen` — all
/// Verdant Scholar photo-hero restyles sharing `shared/widgets/`. This file
/// only ever logs in as `AppRole.admin`, so only `AdminHomeScreen` is built
/// here and needs its own `AdminDashboardProvider`/`NotificationProvider`
/// in scope the same way the real `app.dart` MultiProvider supplies them —
/// `PlaceholderScreen` itself is only used for `/unauthorized` now.)
Widget _appWith(
  AuthProvider authProvider, {
  AdminDashboardRepository? dashboardRepository,
  NotificationRepository? notificationRepository,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AdminDashboardProvider>(
          create: (_) => AdminDashboardProvider(dashboardRepository ?? _MockAdminDashboardRepository()),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationRepository ?? _MockNotificationRepository()),
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(routerConfig: buildAppRouter(context.read<AuthProvider>())),
      ),
    );

void main() {
  late _MockAuthRepository repository;
  late _MockAdminDashboardRepository dashboardRepository;
  late _MockNotificationRepository notificationRepository;

  setUp(() {
    repository = _MockAuthRepository();

    // AdminHomeScreen kicks both of these off from initState — every test
    // that reaches the admin dashboard needs them stubbed or the real
    // (unmocked) call throws inside a microtask `pumpAndSettle` can't see.
    dashboardRepository = _MockAdminDashboardRepository();
    when(() => dashboardRepository.getStats()).thenAnswer((_) async => const Result.success(_emptyStats));
    when(() => dashboardRepository.getUpcomingExams(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success(<UpcomingExamSummary>[]));

    notificationRepository = _MockNotificationRepository();
    when(() => notificationRepository.getNotifications(limit: any(named: 'limit'), unreadOnly: any(named: 'unreadOnly')))
        .thenAnswer((_) async => const Result.success((0, <AppNotification>[])));
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

    await tester.pumpWidget(_appWith(authProvider, dashboardRepository: dashboardRepository, notificationRepository: notificationRepository));
    // Let restoreSession()'s Future resolve and the router react to it.
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a restored authenticated session leaves splash and lands on that role\'s home', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _adminSession);
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider, dashboardRepository: dashboardRepository, notificationRepository: notificationRepository));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AdminHomeScreen), findsOneWidget);
  });

  testWidgets('login() success navigates from the login screen to that role\'s home', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Result.success(_adminSession));
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider, dashboardRepository: dashboardRepository, notificationRepository: notificationRepository));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await authProvider.login(email: 'admin@test.com', password: 'secret');
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomeScreen), findsOneWidget);
  });

  testWidgets('logout() from a dashboard returns to the login screen', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _adminSession);
    when(() => repository.logout(any())).thenAnswer((_) async => const Result.success(null));
    final authProvider = AuthProvider(repository);

    await tester.pumpWidget(_appWith(authProvider, dashboardRepository: dashboardRepository, notificationRepository: notificationRepository));
    await tester.pumpAndSettle();
    expect(find.byType(AdminHomeScreen), findsOneWidget);

    // The dashboard's logout action lives in the avatar's account menu now
    // (see `AdminHomeScreen`'s `_AdminAppBar`), not a standalone icon button.
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
