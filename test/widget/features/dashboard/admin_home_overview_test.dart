import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/dashboard/data/models/admin_dashboard_overview.dart';
import 'package:cloud_lms/features/dashboard/data/repositories/admin_dashboard_repository.dart';
import 'package:cloud_lms/features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/admin_home_screen.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _Auth extends Mock implements AuthRepository {}

class _Dash extends Mock implements AdminDashboardRepository {}

class _Notif extends Mock implements NotificationRepository {}

void main() {
  testWidgets("Today's Overview shows the attendance ring beside students, pending fees and exams", (tester) async {
    tester.view.physicalSize = const Size(390, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final auth = _Auth();
    when(() => auth.restoreSession()).thenAnswer((_) async => AuthSession(
          user: const AppUser(id: 'u1', fullName: 'Sabin Admin', email: 'a@s.test', role: AppRole.admin),
          accessToken: 'a',
          refreshToken: 'r',
        ));
    final dash = _Dash();
    when(() => dash.getStats()).thenAnswer((_) async => const Result.success(AdminDashboardStats(
          totalStudents: 412,
          studentsChangePercent: 4,
          totalTeachers: 28,
          pendingFeesCount: 17,
          attendanceRatePercent: 92,
          attendanceChangePercent: 1,
        )));
    when(() => dash.getUpcomingExams(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success([
          UpcomingExamSummary(subject: 'Maths', className: 'Class 10', daysLeft: 3),
        ]));
    final notif = _Notif();
    when(() => notif.getNotifications(limit: any(named: 'limit'), unreadOnly: any(named: 'unreadOnly')))
        .thenAnswer((_) async => const Result.success((0, <AppNotification>[])));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider(dash)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notif)),
      ],
      child: const MaterialApp(home: AdminHomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Attendance this month'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('+1% vs last month'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Pending fees'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
