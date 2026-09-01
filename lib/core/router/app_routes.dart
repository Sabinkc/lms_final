/// Centralized path constants. No screen should hard-code a route string —
/// import this instead, so a path rename is a one-file diff.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';

  static const String adminHome = '/admin';
  static const String teacherHome = '/teacher';
  static const String studentHome = '/student';
  static const String parentHome = '/parent';

  static const String unauthorized = '/unauthorized';

  // Admin management (docs/production_roadmap.md Phase B).
  static const String adminClasses = '/admin/classes';
  static String adminClassSections(String classId) => '/admin/classes/$classId/sections';
  static const String adminTeachers = '/admin/teachers';
  static const String adminStudents = '/admin/students';
  static const String adminParents = '/admin/parents';

  // Departments (docs/production_roadmap.md Phase L2).
  static const String adminDepartments = '/admin/departments';

  // Attendance (docs/production_roadmap.md Phase C).
  static const String teacherMarkAttendance = '/teacher/attendance/mark';
  static const String teacherAttendanceHistory = '/teacher/attendance/history';
  static const String adminAttendanceOverview = '/admin/attendance/overview';
  static const String adminAttendanceCorrections = '/admin/attendance/corrections';
  static const String studentMyAttendance = '/student/attendance';
  static const String parentChildAttendance = '/parent/attendance';

  // Assignments (docs/production_roadmap.md Phase D, System A).
  static const String assignments = '/assignments';
  static String assignmentDetail(String id) => '/assignments/$id';

  // Notices (docs/production_roadmap.md Phase E).
  static const String notices = '/notices';
  static String noticeDetail(String id) => '/notices/$id';

  // Exams & Results (docs/production_roadmap.md Phase F, System B).
  static const String exams = '/exams';
  static String examPublishResults(String examId) => '/exams/$examId/publish-results';
  static String examResults(String examId) => '/exams/$examId/results';

  // Fees & Payroll (docs/production_roadmap.md Phase G).
  static const String adminFees = '/admin/fees';
  static const String adminFeePayments = '/admin/fees/payments';
  static const String adminPayroll = '/admin/payroll';
  static const String studentFees = '/student/fees';
  static const String parentFees = '/parent/fees';
  static const String teacherPayroll = '/teacher/payroll';

  // Chat (docs/production_roadmap.md Phase H, Teacher/Student only).
  static const String chat = '/chat';
  static String chatThread(String conversationId) => '/chat/$conversationId';

  // Notifications (docs/production_roadmap.md Phase I, shared by all roles).
  static const String notifications = '/notifications';

  // Reports (docs/production_roadmap.md Phase J, Admin only).
  static const String adminReports = '/admin/reports';

  // Backup (docs/production_roadmap.md Phase L1, Admin only).
  static const String adminBackup = '/admin/backup';

  // Timetable (docs/production_roadmap.md Phase L4, Admin/Teacher/Student — not Parent).
  static const String adminTimetable = '/admin/timetable';
  static const String teacherTimetable = '/teacher/timetable';
  static const String studentTimetable = '/student/timetable';

  // Student Follow-ups (docs/production_roadmap.md Phase L5, Admin only).
  static const String adminStudentFollowups = '/admin/student-followups';

  // ID Cards (docs/production_roadmap.md Phase L6, Admin/Student — no Parent access).
  static const String adminIdCards = '/admin/id-cards';
  static const String studentIdCard = '/student/id-card';

  // Dual Calendar (docs/production_roadmap.md Phase L7, Parent only).
  static const String parentDualCalendar = '/parent/dual-calendar';
}
