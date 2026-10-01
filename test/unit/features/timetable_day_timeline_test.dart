import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/presentation/widgets/day_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

TimetablePeriod _p(int n, String start, String end) => TimetablePeriod(
      periodNumber: n,
      subject: 'S$n',
      teacherId: null,
      teacherName: null,
      startTime: start,
      endTime: end,
      room: null,
    );

void main() {
  test('parsePeriodTime handles 12h and 24h free-text times', () {
    expect(parsePeriodTime('10:00 AM'), 600);
    expect(parsePeriodTime('12:15 pm'), 735);
    expect(parsePeriodTime('12:05 AM'), 5);
    expect(parsePeriodTime('14:30'), 870);
    expect(parsePeriodTime('soon'), isNull);
  });

  test('currentWeekday maps Sunday to null', () {
    expect(currentWeekday(DateTime(2026, 10, 5)), 'Monday');
    expect(currentWeekday(DateTime(2026, 10, 4)), isNull);
  });

  test('periodStates marks done / now / next / upcoming on today only', () {
    final periods = [_p(1, '9:00 AM', '10:00 AM'), _p(2, '10:00 AM', '11:00 AM'), _p(3, '11:00 AM', '12:00 PM'), _p(4, '1:00 PM', '2:00 PM')];
    final now = DateTime(2026, 10, 1, 10, 30);
    expect(periodStates(periods, isToday: true, now: now),
        [PeriodState.done, PeriodState.now, PeriodState.next, PeriodState.upcoming]);
    expect(periodStates(periods, isToday: false, now: now), everyElement(PeriodState.upcoming));
  });
}
