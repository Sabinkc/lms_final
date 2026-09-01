import 'timetable_period.dart';

/// Teacher's own view (`GET /api/timetable/teacher`) — flattened to one
/// entry per (class, section, day) that has at least one of this teacher's
/// periods, confirmed by reading `timetableController.js`'s
/// `getTeacherTimetable` directly. Its `periods` are **not** populated
/// server-side here (unlike every other read path) — the caller already
/// knows who they are, so [TimetablePeriod.teacherId]/`.teacherName` will be
/// null/the bare id on these entries.
class TeacherScheduleEntry {
  final String className;
  final String section;
  final String type;
  final String day;
  final List<TimetablePeriod> periods;

  const TeacherScheduleEntry({
    required this.className,
    required this.section,
    required this.type,
    required this.day,
    required this.periods,
  });

  factory TeacherScheduleEntry.fromJson(Map<String, dynamic> json) => TeacherScheduleEntry(
        className: json['className'] as String? ?? '',
        section: json['section'] as String? ?? '',
        type: json['type'] as String? ?? 'fixed',
        day: json['day'] as String? ?? '',
        periods: (json['periods'] as List<dynamic>? ?? const [])
            .map((p) => TimetablePeriod.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
