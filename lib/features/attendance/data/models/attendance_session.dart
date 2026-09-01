/// `AttendanceSession` as returned by `GET /api/attendance/student`
/// (list) — confirmed against `studentattendanceController.js`'s
/// `getAttendanceByDate`. `teacher` is populated with `employeeId` +
/// nested `userId.fullName` on that endpoint specifically.
class AttendanceSessionSummary {
  final String id;
  final String className;
  final String section;
  final String subject;
  final String date;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int totalCount;
  final bool locked;

  const AttendanceSessionSummary({
    required this.id,
    required this.className,
    required this.section,
    required this.subject,
    required this.date,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.totalCount,
    required this.locked,
  });

  factory AttendanceSessionSummary.fromJson(Map<String, dynamic> json) => AttendanceSessionSummary(
        id: json['_id'] as String? ?? json['id'] as String,
        className: json['class'] as String? ?? '',
        section: json['section'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        date: json['date'] as String? ?? '',
        presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
        absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
        lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
        locked: json['locked'] as bool? ?? true,
      );
}
