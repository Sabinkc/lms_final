import 'package:go_router/go_router.dart';

import '../../features/admin_management/presentation/screens/classes_list_screen.dart';
import '../../features/admin_management/presentation/screens/departments_list_screen.dart';
import '../../features/admin_management/presentation/screens/sections_list_screen.dart';
import '../../features/admin_management/presentation/screens/parents_list_screen.dart';
import '../../features/admin_management/presentation/screens/students_list_screen.dart';
import '../../features/admin_management/presentation/screens/teachers_list_screen.dart';
import '../../features/assignments/presentation/screens/assignment_detail_screen.dart';
import '../../features/assignments/presentation/screens/assignments_list_screen.dart';
import '../../features/chat/data/models/group_conversation.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_thread_screen.dart';
import '../../features/exams/data/models/exam.dart';
import '../../features/exams/presentation/screens/exam_results_screen.dart';
import '../../features/exams/presentation/screens/exams_list_screen.dart';
import '../../features/exams/presentation/screens/publish_results_screen.dart';
import '../../features/fees/presentation/screens/admin_fees_screen.dart';
import '../../features/fees/presentation/screens/child_fees_screen.dart';
import '../../features/fees/presentation/screens/my_fees_screen.dart';
import '../../features/fees/presentation/screens/payment_review_screen.dart';
import '../../features/notices/presentation/screens/notice_detail_screen.dart';
import '../../features/notices/presentation/screens/notices_list_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payroll/presentation/screens/my_payslips_screen.dart';
import '../../features/payroll/presentation/screens/payroll_screen.dart';
import '../../features/dual_calendar/presentation/screens/dual_calendar_screen.dart';
import '../../features/id_cards/presentation/screens/admin_id_card_screen.dart';
import '../../features/id_cards/presentation/screens/student_id_card_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/student_followups/presentation/screens/student_followups_screen.dart';
import '../../features/timetable/presentation/screens/admin_timetable_screen.dart';
import '../../features/timetable/presentation/screens/student_timetable_screen.dart';
import '../../features/timetable/presentation/screens/teacher_timetable_screen.dart';
import '../../features/attendance/presentation/screens/admin_attendance_overview_screen.dart';
import '../../features/attendance/presentation/screens/attendance_corrections_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/child_attendance_screen.dart';
import '../../features/attendance/presentation/screens/mark_attendance_screen.dart';
import '../../features/attendance/presentation/screens/my_attendance_screen.dart';
import '../../features/auth/data/models/app_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/dashboard/presentation/screens/more_screen.dart';
import '../../features/dashboard/presentation/screens/role_home_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';
import 'app_routes.dart';
import 'role_shell.dart';

/// Single `GoRouter` for the whole app (docs/architecture.md §4: "not four
/// separate app shells"). Role-based guarding lives entirely in [redirect]
/// below, checked against [AuthProvider] on every navigation attempt —
/// mirrors the CRUD/visibility boundaries in docs/feature_matrix.md (e.g. a
/// Teacher can never land on `/admin`).
///
/// [authProvider] is passed in explicitly (from `service_locator.dart`,
/// the same singleton instance `MultiProvider` exposes to the widget tree)
/// rather than read via `BuildContext` inside [redirect] — `GoRouter`'s
/// `redirect` callback can fire before the widget tree above it exists, so
/// reading a singleton directly is more robust than depending on Provider
/// context lookup timing. [authProvider] is also passed as
/// [GoRouter.refreshListenable] so a login/logout call re-evaluates
/// [redirect] immediately.
GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: AppRole.admin, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.adminHome, builder: (context, state) => const RoleHomeScreen(role: AppRole.admin))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.adminAttendanceOverview, builder: (context, state) => const AdminAttendanceOverviewScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.adminFees, builder: (context, state) => const AdminFeesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.adminMore, builder: (context, state) => const MoreScreen(role: AppRole.admin))],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminClasses,
        builder: (context, state) => const ClassesListScreen(),
        routes: [
          GoRoute(
            path: ':classId/sections',
            builder: (context, state) => SectionsListScreen(classId: state.pathParameters['classId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminTeachers,
        builder: (context, state) => const TeachersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudents,
        builder: (context, state) => const StudentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminParents,
        builder: (context, state) => const ParentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDepartments,
        builder: (context, state) => const DepartmentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAttendanceCorrections,
        builder: (context, state) => const AttendanceCorrectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminFeePayments,
        builder: (context, state) => const PaymentReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayroll,
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBackup,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminTimetable,
        builder: (context, state) => const AdminTimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudentFollowups,
        builder: (context, state) => const StudentFollowupsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminIdCards,
        builder: (context, state) => const AdminIdCardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: AppRole.teacher, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.teacherHome, builder: (context, state) => const RoleHomeScreen(role: AppRole.teacher))],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.teacherMarkAttendance, builder: (context, state) => const MarkAttendanceScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.teacherTimetable, builder: (context, state) => const TeacherTimetableScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.teacherMore, builder: (context, state) => const MoreScreen(role: AppRole.teacher))],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.teacherAttendanceHistory,
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherPayroll,
        builder: (context, state) => const MyPayslipsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: AppRole.student, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.studentHome, builder: (context, state) => const RoleHomeScreen(role: AppRole.student))],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.studentMyAttendance, builder: (context, state) => const MyAttendanceScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.studentTimetable, builder: (context, state) => const StudentTimetableScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.studentMore, builder: (context, state) => const MoreScreen(role: AppRole.student))],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studentFees,
        builder: (context, state) => const MyFeesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentIdCard,
        builder: (context, state) => const StudentIdCardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RoleShell(role: AppRole.parent, navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.parentHome, builder: (context, state) => const RoleHomeScreen(role: AppRole.parent))],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.parentChildAttendance, builder: (context, state) => const ChildAttendanceScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.parentFees, builder: (context, state) => const ChildFeesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.parentMore, builder: (context, state) => const MoreScreen(role: AppRole.parent))],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.parentDualCalendar,
        builder: (context, state) => const DualCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.assignments,
        builder: (context, state) => const AssignmentsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => AssignmentDetailScreen(assignmentId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notices,
        builder: (context, state) => const NoticesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => NoticeDetailScreen(noticeId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.exams,
        builder: (context, state) => const ExamsListScreen(),
        routes: [
          GoRoute(
            path: ':examId/publish-results',
            builder: (context, state) => PublishResultsScreen(exam: state.extra! as Exam),
          ),
          GoRoute(
            path: ':examId/results',
            builder: (context, state) => ExamResultsScreen(examId: state.pathParameters['examId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ChatThreadScreen(
              conversationId: state.pathParameters['id']!,
              group: state.extra as GroupConversation?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Not authorized',
          subtitle: 'Your account role cannot access that screen.',
        ),
      ),
    ],
    redirect: (context, state) => _redirect(authProvider, state.matchedLocation),
  );
}

String? _redirect(AuthProvider authProvider, String location) {
  final status = authProvider.status;

  // Session check still in flight — stay put, whatever "put" is.
  if (status == AuthStatus.unknown) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // Unauthenticated has exactly one valid resting place: login. Splash is
  // NOT one — unlike login, nothing ever navigates a user back to splash on
  // purpose, so if it were treated as "already fine" here (as it used to
  // be, bundled into the same `isAuthRoute` check used below), a freshly
  // restored unauthenticated session would redirect-loop into staying on
  // the splash/loading screen forever instead of ever reaching login.
  if (status == AuthStatus.unauthenticated) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }

  // Authenticated from here down.
  final role = authProvider.role;
  if (role == null) return AppRoutes.login; // Defensive — shouldn't happen.

  final isAuthRoute = location == AppRoutes.login || location == AppRoutes.splash;
  if (isAuthRoute) return _homeFor(role);

  final requiredRoles = _rolesFor(location);
  if (requiredRoles != null && !requiredRoles.contains(role)) {
    return AppRoutes.unauthorized;
  }

  return null;
}

String _homeFor(AppRole role) => switch (role) {
      AppRole.admin => AppRoutes.adminHome,
      AppRole.teacher => AppRoutes.teacherHome,
      AppRole.student => AppRoutes.studentHome,
      AppRole.parent => AppRoutes.parentHome,
    };

/// `null` = no role restriction (splash/login/unauthorized/shared-across-
/// roles). Prefix-based rather than the exact-match switch this used to
/// be — every role-*specific* feature route lives under that role's own
/// top-level segment (e.g. everything under `/admin/...` is Admin-only, see
/// Phase B's `/admin/classes/...`), so a route added under an existing role
/// prefix never needs a matching update here. `/assignments` (Phase D) is
/// the first route genuinely *shared* across all four roles with different
/// per-role behavior handled entirely inside the screen (`GET
/// /api/assignments` is scoped server-side by the caller's token) — it
/// deliberately lives outside every role prefix so it falls through to "no
/// restriction" here rather than needing a fifth entry in this function.
///
/// `/chat` (Phase H) is the first route restricted to a genuine *subset* of
/// roles rather than exactly one or all four — the backend rejects
/// Admin/Parent sockets outright and has no Parent participant field in the
/// schema at all (`api_spec.md` §7), so it can't simply fall through to "no
/// restriction" like `/assignments` does. This is why the return type is a
/// `Set<AppRole>`, not a single `AppRole` — every other case still returns a
/// singleton set, so this generalization changes nothing for them.
Set<AppRole>? _rolesFor(String location) {
  if (_isUnder(location, AppRoutes.adminHome)) return {AppRole.admin};
  if (_isUnder(location, AppRoutes.teacherHome)) return {AppRole.teacher};
  if (_isUnder(location, AppRoutes.studentHome)) return {AppRole.student};
  if (_isUnder(location, AppRoutes.parentHome)) return {AppRole.parent};
  if (_isUnder(location, AppRoutes.chat)) return {AppRole.teacher, AppRole.student};
  return null;
}

bool _isUnder(String location, String rootPath) => location == rootPath || location.startsWith('$rootPath/');
