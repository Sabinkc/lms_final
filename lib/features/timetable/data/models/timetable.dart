import 'timetable_day.dart';

/// Admin's own view of one class+section's timetable. `className`/`section`
/// are plain Strings on this document (not `Class`/`Section` refs), same
/// convention `Student.className`/`.section` already use.
class Timetable {
  final String id;
  final String className;
  final String section;
  final String type;
  final int? weekNumber;
  final int year;
  final List<TimetableDay> schedule;

  const Timetable({
    required this.id,
    required this.className,
    required this.section,
    required this.type,
    required this.weekNumber,
    required this.year,
    required this.schedule,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) => Timetable(
        id: json['_id'] as String? ?? json['id'] as String,
        className: json['className'] as String? ?? '',
        section: json['section'] as String? ?? '',
        type: json['type'] as String? ?? 'fixed',
        weekNumber: (json['weekNumber'] as num?)?.toInt(),
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
        schedule: (json['schedule'] as List<dynamic>? ?? const [])
            .map((d) => TimetableDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
