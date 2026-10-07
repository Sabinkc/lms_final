import 'package:flutter/material.dart';

import '../../features/auth/data/models/app_role.dart';
import '../router/app_routes.dart';

/// One destination — icon, label, and the path to push. Used by the Home
/// quick-actions grid and the More screen; both just do
/// `context.push(action.route)`, so no per-item builder wiring is needed
/// here (the actual `GoRoute`/screen-widget mapping stays in
/// `app_router.dart`, same as every route today).
class QuickAction {
  final IconData icon;
  final String label;
  final String route;

  const QuickAction({required this.icon, required this.label, required this.route});
}

/// Everything the Home screen, bottom-nav shell, and More screen need for
/// one role, in one place — replaces the flat `links` list that used to
/// live inline in `app_router.dart`'s `PlaceholderScreen(...)` calls.
///
/// `navTabs` are promoted to persistent bottom-nav branches (see
/// `role_shell.dart`) — deliberately only routes already living under that
/// role's own path prefix (`/admin/...` etc.), never a route shared across
/// roles (`/assignments`, `/chat`, ...), since a shared path can only be
/// registered once in `go_router`'s tree and can't be a branch in more than
/// one role's shell at once. Shared routes are still one tap away via
/// `homeHighlights`/`moreItems`, just not a permanent tab.
///
/// `moreItems` is deliberately **exhaustive** — every destination the old
/// flat button list offered that isn't a `navTab`, so nothing regresses to
/// unreachable. `homeHighlights` is a curated subset shown on Home in
/// addition to the nav tabs, for at-a-glance access to the few
/// highest-value items that don't have their own tab.
class RoleDashboardConfig {
  final String homeTitle;
  final List<String> tabTitles; // Home, then each navTab, then "More" — parallel to the shell's branches.
  final List<QuickAction> navTabs;
  final List<QuickAction> homeHighlights;
  final List<QuickAction> moreItems;

  const RoleDashboardConfig({
    required this.homeTitle,
    required this.tabTitles,
    required this.navTabs,
    required this.homeHighlights,
    required this.moreItems,
  });

  static RoleDashboardConfig forRole(AppRole role) => switch (role) {
    AppRole.admin => admin,
    AppRole.teacher => teacher,
    AppRole.student => student,
    AppRole.parent => parent,
  };

  static const admin = RoleDashboardConfig(
    homeTitle: 'Admin Dashboard',
    tabTitles: ['Admin Dashboard', 'Attendance', 'Fees', 'More'],
    navTabs: [
      QuickAction(icon: Icons.event_available_outlined, label: 'Attendance', route: AppRoutes.adminAttendanceOverview),
      QuickAction(icon: Icons.payments_outlined, label: 'Fees', route: AppRoutes.adminFees),
    ],
    homeHighlights: [
      QuickAction(icon: Icons.groups_outlined, label: 'Manage Students', route: AppRoutes.adminStudents),
      QuickAction(icon: Icons.badge_outlined, label: 'Manage Teachers', route: AppRoutes.adminTeachers),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
      QuickAction(icon: Icons.bar_chart_outlined, label: 'Reports', route: AppRoutes.adminReports),
    ],
    moreItems: [
      QuickAction(icon: Icons.class_outlined, label: 'Manage Classes', route: AppRoutes.adminClasses),
      QuickAction(icon: Icons.groups_outlined, label: 'Manage Students', route: AppRoutes.adminStudents),
      QuickAction(icon: Icons.badge_outlined, label: 'Manage Teachers', route: AppRoutes.adminTeachers),
      QuickAction(icon: Icons.family_restroom_outlined, label: 'Manage Parents', route: AppRoutes.adminParents),
      QuickAction(icon: Icons.apartment_outlined, label: 'Departments', route: AppRoutes.adminDepartments),
      QuickAction(
        icon: Icons.fact_check_outlined,
        label: 'Attendance Corrections',
        route: AppRoutes.adminAttendanceCorrections,
      ),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
      QuickAction(icon: Icons.receipt_long_outlined, label: 'Fee Payment Review', route: AppRoutes.adminFeePayments),
      QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Payroll', route: AppRoutes.adminPayroll),
      QuickAction(icon: Icons.bar_chart_outlined, label: 'Reports', route: AppRoutes.adminReports),
      QuickAction(icon: Icons.backup_outlined, label: 'Backup & Data', route: AppRoutes.adminBackup),
      QuickAction(icon: Icons.calendar_month_outlined, label: 'Timetable', route: AppRoutes.adminTimetable),
      QuickAction(icon: Icons.flag_outlined, label: 'Student Follow-ups', route: AppRoutes.adminStudentFollowups),
      QuickAction(icon: Icons.credit_card_outlined, label: 'ID Cards', route: AppRoutes.adminIdCards),
      QuickAction(icon: Icons.apartment_outlined, label: 'School Profile', route: AppRoutes.adminSchoolProfile),
    ],
  );

  static const teacher = RoleDashboardConfig(
    homeTitle: 'Teacher Dashboard',
    tabTitles: ['Teacher Dashboard', 'Mark Attendance', 'My Timetable', 'More'],
    navTabs: [
      // Short label: "Mark Attendance" wrapped to two lines in the nav bar.
      QuickAction(icon: Icons.event_available_outlined, label: 'Attendance', route: AppRoutes.teacherMarkAttendance),
      QuickAction(icon: Icons.calendar_month_outlined, label: 'My Timetable', route: AppRoutes.teacherTimetable),
    ],
    homeHighlights: [
      QuickAction(icon: Icons.chat_bubble_outline, label: 'Chat', route: AppRoutes.chat),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.history_outlined, label: 'Attendance History', route: AppRoutes.teacherAttendanceHistory),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
    ],
    moreItems: [
      QuickAction(icon: Icons.history_outlined, label: 'Attendance History', route: AppRoutes.teacherAttendanceHistory),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
      QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'My Payslips', route: AppRoutes.teacherPayroll),
      QuickAction(icon: Icons.chat_bubble_outline, label: 'Chat', route: AppRoutes.chat),
    ],
  );

  static const student = RoleDashboardConfig(
    homeTitle: 'Student Dashboard',
    tabTitles: ['Student Dashboard', 'My Attendance', 'My Timetable', 'More'],
    navTabs: [
      QuickAction(icon: Icons.event_available_outlined, label: 'My Attendance', route: AppRoutes.studentMyAttendance),
      QuickAction(icon: Icons.calendar_month_outlined, label: 'My Timetable', route: AppRoutes.studentTimetable),
    ],
    homeHighlights: [
      QuickAction(icon: Icons.chat_bubble_outline, label: 'Chat', route: AppRoutes.chat),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.payments_outlined, label: 'My Fees', route: AppRoutes.studentFees),
      QuickAction(icon: Icons.credit_card_outlined, label: 'My ID Card', route: AppRoutes.studentIdCard),
    ],
    moreItems: [
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
      QuickAction(icon: Icons.payments_outlined, label: 'My Fees', route: AppRoutes.studentFees),
      QuickAction(icon: Icons.chat_bubble_outline, label: 'Chat', route: AppRoutes.chat),
      QuickAction(icon: Icons.credit_card_outlined, label: 'My ID Card', route: AppRoutes.studentIdCard),
    ],
  );

  static const parent = RoleDashboardConfig(
    homeTitle: 'Parent Dashboard',
    tabTitles: ['Parent Dashboard', 'Attendance', 'Fees', 'More'],
    navTabs: [
      QuickAction(icon: Icons.event_available_outlined, label: 'Attendance', route: AppRoutes.parentChildAttendance),
      QuickAction(icon: Icons.payments_outlined, label: 'Fees', route: AppRoutes.parentFees),
    ],
    homeHighlights: [
      QuickAction(icon: Icons.event_note_outlined, label: 'Dual Calendar', route: AppRoutes.parentDualCalendar),
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
    ],
    moreItems: [
      QuickAction(icon: Icons.assignment_outlined, label: 'Assignments', route: AppRoutes.assignments),
      QuickAction(icon: Icons.campaign_outlined, label: 'Notices', route: AppRoutes.notices),
      QuickAction(icon: Icons.quiz_outlined, label: 'Exams', route: AppRoutes.exams),
      QuickAction(icon: Icons.event_note_outlined, label: 'Dual Calendar', route: AppRoutes.parentDualCalendar),
    ],
  );
}
