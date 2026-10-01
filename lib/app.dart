import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'features/admin_management/presentation/providers/department_provider.dart';
import 'features/admin_management/presentation/providers/parent_provider.dart';
import 'features/admin_management/presentation/providers/student_provider.dart';
import 'features/admin_management/presentation/providers/student_profile_provider.dart';
import 'features/admin_management/presentation/providers/student_day_attendance_provider.dart';
import 'features/admin_management/presentation/providers/teacher_provider.dart';
import 'features/assignments/presentation/providers/assignment_provider.dart';
import 'features/attendance/presentation/providers/admin_attendance_provider.dart';
import 'features/attendance/presentation/providers/attendance_provider.dart';
import 'features/attendance/presentation/providers/self_attendance_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/backup/presentation/providers/backup_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/exams/presentation/providers/exam_provider.dart';
import 'features/exams/presentation/providers/exam_result_provider.dart';
import 'features/fees/presentation/providers/fee_provider.dart';
import 'features/fees/presentation/providers/self_fee_provider.dart';
import 'features/notices/presentation/providers/notice_provider.dart';
import 'features/payroll/presentation/providers/my_payslips_provider.dart';
import 'features/payroll/presentation/providers/payroll_provider.dart';
import 'features/id_cards/presentation/providers/admin_id_card_provider.dart';
import 'features/id_cards/presentation/providers/student_id_card_provider.dart';
import 'features/reports/presentation/providers/reports_provider.dart';
import 'features/student_followups/presentation/providers/student_followup_provider.dart';
import 'features/timetable/presentation/providers/admin_timetable_provider.dart';
import 'features/timetable/presentation/providers/student_timetable_provider.dart';
import 'features/timetable/presentation/providers/teacher_timetable_provider.dart';

/// Root widget. `MultiProvider` here is where every feature's provider
/// gets exposed to the widget tree — each entry is that feature's own
/// `ChangeNotifier`, constructed via [sl]. **There is no `AppProvider`**:
/// adding a new feature means adding one more line to this list, never
/// merging state into an existing provider or a shared catch-all one.
class CloudsLmsApp extends StatelessWidget {
  const CloudsLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: sl<AuthProvider>()),
        ChangeNotifierProvider<AcademicStructureProvider>(create: (_) => sl<AcademicStructureProvider>()),
        ChangeNotifierProvider<TeacherProvider>(create: (_) => sl<TeacherProvider>()),
        ChangeNotifierProvider<StudentProvider>(create: (_) => sl<StudentProvider>()),
        ChangeNotifierProvider<StudentProfileProvider>(create: (_) => sl<StudentProfileProvider>()),
        ChangeNotifierProvider<StudentDayAttendanceProvider>(create: (_) => sl<StudentDayAttendanceProvider>()),
        ChangeNotifierProvider<ParentProvider>(create: (_) => sl<ParentProvider>()),
        ChangeNotifierProvider<DepartmentProvider>(create: (_) => sl<DepartmentProvider>()),
        ChangeNotifierProvider<AttendanceProvider>(create: (_) => sl<AttendanceProvider>()),
        ChangeNotifierProvider<AdminAttendanceProvider>(create: (_) => sl<AdminAttendanceProvider>()),
        ChangeNotifierProvider<SelfAttendanceProvider>(create: (_) => sl<SelfAttendanceProvider>()),
        ChangeNotifierProvider<AssignmentProvider>(create: (_) => sl<AssignmentProvider>()),
        ChangeNotifierProvider<NoticeProvider>(create: (_) => sl<NoticeProvider>()),
        ChangeNotifierProvider<ExamProvider>(create: (_) => sl<ExamProvider>()),
        ChangeNotifierProvider<ExamResultProvider>(create: (_) => sl<ExamResultProvider>()),
        ChangeNotifierProvider<FeeProvider>(create: (_) => sl<FeeProvider>()),
        ChangeNotifierProvider<SelfFeeProvider>(create: (_) => sl<SelfFeeProvider>()),
        ChangeNotifierProvider<PayrollProvider>(create: (_) => sl<PayrollProvider>()),
        ChangeNotifierProvider<MyPayslipsProvider>(create: (_) => sl<MyPayslipsProvider>()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => sl<ChatProvider>()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => sl<NotificationProvider>()),
        ChangeNotifierProvider<ReportsProvider>(create: (_) => sl<ReportsProvider>()),
        ChangeNotifierProvider<AdminDashboardProvider>(create: (_) => sl<AdminDashboardProvider>()),
        ChangeNotifierProvider<BackupProvider>(create: (_) => sl<BackupProvider>()),
        ChangeNotifierProvider<AdminTimetableProvider>(create: (_) => sl<AdminTimetableProvider>()),
        ChangeNotifierProvider<TeacherTimetableProvider>(create: (_) => sl<TeacherTimetableProvider>()),
        ChangeNotifierProvider<StudentTimetableProvider>(create: (_) => sl<StudentTimetableProvider>()),
        ChangeNotifierProvider<StudentFollowupProvider>(create: (_) => sl<StudentFollowupProvider>()),
        ChangeNotifierProvider<AdminIdCardProvider>(create: (_) => sl<AdminIdCardProvider>()),
        ChangeNotifierProvider<StudentIdCardProvider>(create: (_) => sl<StudentIdCardProvider>()),
      ],
      child: Builder(
        builder: (context) {
          final router = buildAppRouter(context.read<AuthProvider>());
          return MaterialApp.router(
            title: 'CloudsLMS',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
