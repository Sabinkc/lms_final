/// `GET /admin/dashboard/stats` response shape, confirmed by reading
/// `Dashboardcontroller.js`'s `getStatCards` directly. `pendingFees` on that
/// endpoint is a plain count (`{value}`), not a `{value, changePercent}`
/// trio like the other fields — no history is computed for it server-side.
class AdminDashboardStats {
  final int totalStudents;
  final double studentsChangePercent;
  final int totalTeachers;
  final int pendingFeesCount;
  final int attendanceRatePercent;
  final double attendanceChangePercent;

  const AdminDashboardStats({
    required this.totalStudents,
    required this.studentsChangePercent,
    required this.totalTeachers,
    required this.pendingFeesCount,
    required this.attendanceRatePercent,
    required this.attendanceChangePercent,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final students = json['totalStudents'] as Map<String, dynamic>? ?? const {};
    final teachers = json['totalTeachers'] as Map<String, dynamic>? ?? const {};
    final pendingFees = json['pendingFees'] as Map<String, dynamic>? ?? const {};
    final attendance = json['attendanceRate'] as Map<String, dynamic>? ?? const {};
    return AdminDashboardStats(
      totalStudents: (students['value'] as num?)?.toInt() ?? 0,
      studentsChangePercent: (students['changePercent'] as num?)?.toDouble() ?? 0,
      totalTeachers: (teachers['value'] as num?)?.toInt() ?? 0,
      pendingFeesCount: (pendingFees['value'] as num?)?.toInt() ?? 0,
      attendanceRatePercent: (attendance['value'] as num?)?.toInt() ?? 0,
      attendanceChangePercent: (attendance['changePercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One row of `GET /admin/dashboard/exams` (`Dashboardcontroller.js`'s
/// `getUpcomingExams`) — already sorted soonest-first by the backend.
class UpcomingExamSummary {
  final String subject;
  final String className;
  final int daysLeft;

  const UpcomingExamSummary({required this.subject, required this.className, required this.daysLeft});

  factory UpcomingExamSummary.fromJson(Map<String, dynamic> json) => UpcomingExamSummary(
        subject: json['subject'] as String? ?? '',
        className: json['className'] as String? ?? '',
        daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 0,
      );
}
