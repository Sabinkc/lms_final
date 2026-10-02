import 'day_attendance_record.dart';

/// One class's attendance on one date. Originally modeled on
/// `studentattendanceController.js`'s session documents, but the live
/// `GET /api/attendance/student?date=` actually returns one flat row per
/// student (`{date, status, studentName, className}` — checked 2026-10-01
/// as both Admin and Teacher), so [fromDayRecords] builds these summaries
/// by grouping those rows per class. [fromJson] still reads a real session
/// document if the endpoint ever returns one.
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

  /// "Class 10 — A", skipping empty parts (grouped rows carry the class
  /// and section already joined in [className], with no separate section).
  String get title => [className, section].where((p) => p.isNotEmpty).join(' — ');

  /// Groups per-student day rows into one summary per class + date, in
  /// first-seen order. `leave`/`halfday` rows count toward [totalCount]
  /// only. [locked] is false: the rows don't say, so no lock is claimed.
  static List<AttendanceSessionSummary> fromDayRecords(List<DayAttendanceRecord> records) {
    final groups = <String, List<DayAttendanceRecord>>{};
    for (final r in records) {
      groups.putIfAbsent('${r.className}|${r.date}', () => []).add(r);
    }
    return [
      for (final entry in groups.entries)
        AttendanceSessionSummary(
          id: entry.key,
          className: entry.value.first.className,
          section: '',
          subject: '',
          date: entry.value.first.date,
          presentCount: entry.value.where((r) => r.status == 'present').length,
          absentCount: entry.value.where((r) => r.status == 'absent').length,
          lateCount: entry.value.where((r) => r.status == 'late').length,
          totalCount: entry.value.length,
          locked: false,
        ),
    ];
  }

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
