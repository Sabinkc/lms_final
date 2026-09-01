import '../../../core/router/app_routes.dart';
import '../../auth/data/models/app_role.dart';
import '../data/models/app_notification.dart';

/// `implementation_backlog.md` E11-F2 — maps a notification's `refModel`
/// (+ the viewer's own role, since several targets are role-specific
/// screens rather than one shared id-based route) to somewhere to navigate.
/// `null` means "nothing to navigate to" — the tap still marks it read, it
/// just doesn't push a route.
///
/// Only `Assignment` has a real per-id detail route (`/assignments/:id`) to
/// deep-link into directly. Every other `refModel` maps to that target's
/// *list* screen, not a specific item within it — `Exam`/`Result` share one
/// list with no per-id route (`ExamsListScreen`'s inline `ExpansionTile`
/// pattern, no `GET /:id` for non-Admin roles), Attendance has no per-id
/// route at all (session-list/history based), and `Fee`/`AttendanceCorrection`
/// are role-specific screens where finding the exact item isn't worth a
/// bespoke query per notification type. `Subscription` has no screen in
/// this app at all (SuperAdmin/Subscriptions module, out of scope per
/// `production_roadmap.md` §4 item 5).
String? routeForNotification(AppNotification notification, AppRole role) {
  switch (notification.refModel) {
    case 'Assignment':
      return notification.refId != null ? AppRoutes.assignmentDetail(notification.refId!) : AppRoutes.assignments;

    case 'Exam':
    case 'Result':
      return AppRoutes.exams;

    case 'Fee':
      return switch (role) {
        AppRole.admin => AppRoutes.adminFees,
        AppRole.student => AppRoutes.studentFees,
        AppRole.parent => AppRoutes.parentFees,
        AppRole.teacher => null,
      };

    case 'Attendance':
    case 'AttendanceSession':
    case 'AttendanceRecord':
      return switch (role) {
        AppRole.admin => AppRoutes.adminAttendanceOverview,
        AppRole.teacher => AppRoutes.teacherAttendanceHistory,
        AppRole.student => AppRoutes.studentMyAttendance,
        AppRole.parent => AppRoutes.parentChildAttendance,
      };

    case 'AttendanceCorrection':
      return role == AppRole.admin ? AppRoutes.adminAttendanceCorrections : null;

    default:
      return null;
  }
}
