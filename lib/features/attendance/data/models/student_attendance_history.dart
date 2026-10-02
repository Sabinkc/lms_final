/// `GET /api/attendance/student/:studentId`'s response shape, confirmed
/// against `studentattendanceController.js`'s `getAttendanceByStudent`.
/// Authorized for the student themselves, their linked parent, any teacher
/// in the school, or an admin (`Attendance.service.js`'s
/// `isAuthorizedForStudent`) — the same one endpoint backs both the Student
/// "My Attendance" screen and the Parent "Child's Attendance" screen.
class AttendanceRecordDetail {
  final String id;
  final String status;
  final String remarks;
  final String date;
  final String subject;
  final String className;
  final String section;

  const AttendanceRecordDetail({
    required this.id,
    required this.status,
    required this.remarks,
    required this.date,
    required this.subject,
    required this.className,
    required this.section,
  });

  factory AttendanceRecordDetail.fromJson(Map<String, dynamic> json) {
    final session = json['attendanceSession'] as Map<String, dynamic>?;
    return AttendanceRecordDetail(
      id: json['_id'] as String? ?? json['id'] as String,
      status: json['status'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      date: session?['date'] as String? ?? '',
      subject: session?['subject'] as String? ?? '',
      className: session?['class'] as String? ?? '',
      section: session?['section'] as String? ?? '',
    );
  }
}

class AttendanceHistorySummary {
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int halfDay;
  final int total;
  final int percentage;

  const AttendanceHistorySummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.halfDay,
    required this.total,
    required this.percentage,
  });

  factory AttendanceHistorySummary.fromJson(Map<String, dynamic> json) => AttendanceHistorySummary(
    present: (json['present'] as num?)?.toInt() ?? 0,
    absent: (json['absent'] as num?)?.toInt() ?? 0,
    late: (json['late'] as num?)?.toInt() ?? 0,
    leave: (json['leave'] as num?)?.toInt() ?? 0,
    halfDay: (json['halfDay'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toInt() ?? 0,
  );
}

class StudentAttendanceHistory {
  final String studentName;
  final AttendanceHistorySummary summary;
  final List<AttendanceRecordDetail> records;

  const StudentAttendanceHistory({required this.studentName, required this.summary, required this.records});

  factory StudentAttendanceHistory.fromJson(Map<String, dynamic> json) => StudentAttendanceHistory(
    studentName: (json['student'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    summary: AttendanceHistorySummary.fromJson(json['summary'] as Map<String, dynamic>),
    records: (json['data'] as List).map((r) => AttendanceRecordDetail.fromJson(r as Map<String, dynamic>)).toList(),
  );
}
