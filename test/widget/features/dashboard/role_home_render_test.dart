import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/self_attendance_provider.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/student_home_screen.dart';
import 'package:cloud_lms/features/dashboard/presentation/screens/teacher_home_screen.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_provider.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/self_fee_provider.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/teacher_timetable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _Auth extends Mock implements AuthRepository {}

class _Attendance extends Mock implements AttendanceRepository {}

class _Fees extends Mock implements FeeRepository {}

class _Payments extends Mock implements PaymentRepository {}

class _Students extends Mock implements StudentRepository {}

class _Exams extends Mock implements ExamRepository {}

class _Timetable extends Mock implements TimetableRepository {}

class _Notif extends Mock implements NotificationRepository {}

/// Student/Teacher Home were never rendered by any test, so a layout error
/// (an `Expanded` directly in the scroll view's Column) blanked the whole
/// body on-device while every test stayed green. These only check that each
/// home lays out and shows its sections.
void main() {
  late _Auth auth;
  late _Attendance attendance;
  late _Exams exams;
  late _Notif notif;

  setUp(() {
    attendance = _Attendance();
    exams = _Exams();
    notif = _Notif();
    when(() => exams.getMyExams()).thenAnswer((_) async => const Result.success([]));
    when(() => notif.getNotifications(limit: any(named: 'limit'), unreadOnly: any(named: 'unreadOnly')))
        .thenAnswer((_) async => const Result.success((0, <AppNotification>[])));
  });

  void signInAs(AppRole role) {
    auth = _Auth();
    when(() => auth.restoreSession()).thenAnswer((_) async => AuthSession(
          user: AppUser(id: 'u1', fullName: 'Amy Example', email: 'a@s.test', role: role),
          accessToken: 'a',
          refreshToken: 'r',
        ));
  }

  Future<void> pumpHome(WidgetTester tester, Widget home, List<ChangeNotifierProvider> extra) async {
    tester.view.physicalSize = const Size(390, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(auth)),
        ChangeNotifierProvider(create: (_) => ExamProvider(exams)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notif)),
        ...extra,
      ],
      child: MaterialApp(home: home),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Student Home lays out its quick actions and overview', (tester) async {
    signInAs(AppRole.student);
    when(() => attendance.getMyStudentId()).thenAnswer((_) async => const Result.failure(NotFoundException()));
    final students = _Students();
    when(() => students.getMyProfile()).thenAnswer((_) async => const Result.failure(NotFoundException()));

    await pumpHome(tester, const StudentHomeScreen(), [
      ChangeNotifierProvider<SelfAttendanceProvider>(create: (_) => SelfAttendanceProvider(attendance)),
      ChangeNotifierProvider<SelfFeeProvider>(create: (_) => SelfFeeProvider(_Fees(), _Payments(), students)),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text("Today's Overview"), findsOneWidget);
    expect(find.text('Attendance Rate'), findsOneWidget);
  });

  testWidgets('Teacher Home lays out its quick actions and overview', (tester) async {
    signInAs(AppRole.teacher);
    when(() => attendance.getMySections()).thenAnswer((_) async => const Result.success([]));
    final timetable = _Timetable();
    when(() => timetable.getTeacherTimetable()).thenAnswer((_) async => const Result.success([]));

    await pumpHome(tester, const TeacherHomeScreen(), [
      ChangeNotifierProvider<AttendanceProvider>(create: (_) => AttendanceProvider(attendance)),
      ChangeNotifierProvider<TeacherTimetableProvider>(create: (_) => TeacherTimetableProvider(timetable)),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text("Today's Overview"), findsOneWidget);
  });
}
