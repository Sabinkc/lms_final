import 'package:cloud_lms/features/attendance/data/models/student_attendance_history.dart';
import 'package:cloud_lms/features/attendance/presentation/widgets/attendance_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AttendanceRecordDetail _rec(String date, String status) => AttendanceRecordDetail.fromJson({
      '_id': '$date$status',
      'status': status,
      'attendanceSession': {'date': '${date}T00:00:00.000Z', 'subject': 'General', 'class': '10', 'section': 'A'},
    });

void main() {
  test('rate series counts late as attended, absent and leave as not', () {
    final series = attendanceRateSeries([
      _rec('2026-09-01', 'present'),
      _rec('2026-09-02', 'absent'),
      _rec('2026-09-03', 'late'),
      _rec('2026-09-04', 'leave'),
    ]);
    expect(series, [1.0, 0.5, 2 / 3, 0.5]);
  });

  testWidgets('shows 35 days ending with the latest week, and a day with two sessions takes the worse status',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AttendanceHeatmap(records: [
            _rec('2026-10-02', 'present'),
            _rec('2026-10-02', 'absent'), // second session the same day
            _rec('2026-09-15', 'late'),
          ]),
        ),
      ),
    ));
    expect(find.text('Last 5 weeks'), findsOneWidget);
    expect(find.bySemanticsLabel('Oct 2, absent'), findsOneWidget);
    expect(find.bySemanticsLabel('Sep 15, late'), findsOneWidget);
    // 35 day cells: Sun 30 Aug … Sat 3 Oct.
    expect(find.bySemanticsLabel(RegExp(r'^[A-Z][a-z]{2} \d+')), findsNWidgets(35));
    expect(find.text('Oct 1'), findsOneWidget);
  });
}
