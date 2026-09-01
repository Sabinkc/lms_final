import 'timetable_period.dart';

/// `timetableSchema.js`'s `schedule.day` enum is exactly these 6 full names
/// (Monday–Saturday, no Sunday) — a 6-day school week, not the 3-letter
/// `Mon`–`Sat` shorthand `production_roadmap.md`'s original Phase L4 note
/// guessed before this targeted read.
const List<String> timetableWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

class TimetableDay {
  final String day;
  final List<TimetablePeriod> periods;

  const TimetableDay({required this.day, required this.periods});

  factory TimetableDay.fromJson(Map<String, dynamic> json) => TimetableDay(
        day: json['day'] as String? ?? '',
        periods: (json['periods'] as List<dynamic>? ?? const [])
            .map((p) => TimetablePeriod.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class TimetableDayInput {
  final String day;
  final List<TimetablePeriodInput> periods;

  const TimetableDayInput({required this.day, required this.periods});

  Map<String, dynamic> toJson() => {
        'day': day,
        'periods': periods.map((p) => p.toJson()).toList(),
      };
}
