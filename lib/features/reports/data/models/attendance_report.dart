/// `GET /reports/attendance` response shape, confirmed by reading
/// `Reportcontroller.js`'s `getAttendanceReport` directly. Only this one of
/// the four report endpoints takes a query filter (`startDate`/`endDate`,
/// both required together or the filter is skipped entirely — confirmed in
/// the handler). There's no server-side class filter; [classBreakdown] is
/// already grouped by `"<class>-<section>"` server-side instead.
///
/// `attendanceRate` has the same string-or-`0` shape as `AcademicReport`'s
/// `passRate` — see that class's doc comment.
class AttendanceReport {
  final int total;
  final int present;
  final int absent;
  final int late;
  final double attendanceRate;
  final int totalStudents;
  final Map<String, ClassAttendanceBreakdown> classBreakdown;

  const AttendanceReport({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendanceRate,
    required this.totalStudents,
    required this.classBreakdown,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final breakdown = json['classBreakdown'] as Map<String, dynamic>? ?? const {};
    return AttendanceReport(
      total: (summary['total'] as num?)?.toInt() ?? 0,
      present: (summary['present'] as num?)?.toInt() ?? 0,
      absent: (summary['absent'] as num?)?.toInt() ?? 0,
      late: (summary['late'] as num?)?.toInt() ?? 0,
      attendanceRate: double.tryParse('${summary['attendanceRate']}') ?? 0,
      totalStudents: (summary['totalStudents'] as num?)?.toInt() ?? 0,
      classBreakdown: breakdown.map(
        (key, value) => MapEntry(key, ClassAttendanceBreakdown.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

class ClassAttendanceBreakdown {
  final int present;
  final int absent;
  final int late;
  final int total;

  const ClassAttendanceBreakdown({
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
  });

  factory ClassAttendanceBreakdown.fromJson(Map<String, dynamic> json) => ClassAttendanceBreakdown(
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        late: (json['late'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}
