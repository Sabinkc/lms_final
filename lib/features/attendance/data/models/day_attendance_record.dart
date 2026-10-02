/// One student's attendance on one day, as `GET /attendance/student?date=`
/// actually returns it (checked against the live API 2026-10-01): a flat
/// row with no ids — `{date, status, studentName, className}`, where
/// `className` is the class and section joined ("Class 10 A"). A student
/// with several sessions that day (one per subject) gets several rows.
class DayAttendanceRecord {
  final String date;
  final String status;
  final String studentName;
  final String className;

  const DayAttendanceRecord({
    required this.date,
    required this.status,
    required this.studentName,
    required this.className,
  });

  factory DayAttendanceRecord.fromJson(Map<String, dynamic> json) => DayAttendanceRecord(
    date: json['date'] as String? ?? '',
    status: (json['status'] as String? ?? '').toLowerCase(),
    studentName: json['studentName'] as String? ?? '',
    className: json['className'] as String? ?? '',
  );
}
