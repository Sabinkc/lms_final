import 'timetable_day.dart';

/// Student's own view (`GET /api/timetable/my`) — a genuinely different
/// response shape from Admin's [Timetable], confirmed by reading
/// `timetableController.js`'s `getMyTimetable` directly: never 404s, returns
/// an `empty: true` shell with an empty [todaySchedule] instead when no
/// timetable has been set up for the student's class/section yet.
class MyTimetable {
  final bool empty;
  final String type;
  final int? weekNumber;
  final String today;
  final TimetableDay todaySchedule;
  final List<TimetableDay> fullSchedule;

  const MyTimetable({
    required this.empty,
    required this.type,
    required this.weekNumber,
    required this.today,
    required this.todaySchedule,
    required this.fullSchedule,
  });

  factory MyTimetable.fromJson(Map<String, dynamic> json) => MyTimetable(
        empty: json['empty'] as bool? ?? false,
        type: json['type'] as String? ?? 'fixed',
        weekNumber: (json['weekNumber'] as num?)?.toInt(),
        today: json['today'] as String? ?? '',
        todaySchedule: TimetableDay.fromJson(json['todaySchedule'] as Map<String, dynamic>? ?? const {}),
        fullSchedule: (json['fullSchedule'] as List<dynamic>? ?? const [])
            .map((d) => TimetableDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
