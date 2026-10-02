import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/timetable/data/models/my_timetable.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_day.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/student_timetable_provider.dart';
import 'package:cloud_lms/features/timetable/presentation/screens/student_timetable_screen.dart';
import 'package:cloud_lms/features/timetable/presentation/widgets/day_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _emptyTimetable = MyTimetable(
  empty: true,
  type: 'fixed',
  weekNumber: null,
  today: 'Wednesday',
  todaySchedule: TimetableDay(day: 'Wednesday', periods: []),
  fullSchedule: [],
);

const _realTimetable = MyTimetable(
  empty: false,
  type: 'fixed',
  weekNumber: null,
  today: 'Monday',
  todaySchedule: TimetableDay(
    day: 'Monday',
    periods: [
      TimetablePeriod(periodNumber: 1, subject: 'Science', teacherId: 'tch2', teacherName: 'Sam Teacher', startTime: '9:00 AM', endTime: '10:00 AM', room: null),
    ],
  ),
  fullSchedule: [
    TimetableDay(day: 'Monday', periods: []),
    TimetableDay(day: 'Tuesday', periods: []),
  ],
);

Widget _wrap(StudentTimetableProvider provider) => ChangeNotifierProvider<StudentTimetableProvider>.value(
      value: provider,
      child: const MaterialApp(home: StudentTimetableScreen()),
    );

void main() {
  late _MockTimetableRepository repository;

  setUp(() {
    repository = _MockTimetableRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getMyTimetable()).thenAnswer((_) => Completer<Result<MyTimetable>>().future);
    final provider = StudentTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty timetable shows the never-404 empty state, not an error', (tester) async {
    when(() => repository.getMyTimetable()).thenAnswer((_) async => const Result.success(_emptyTimetable));
    final provider = StudentTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No timetable set up for your class yet'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getMyTimetable()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success(_realTimetable);
    });
    final provider = StudentTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // findsWidgets: depending on the real clock the period can also show in
    // the "Up next" card.
    expect(find.textContaining('Science'), findsWidgets);
  });

  testWidgets('real timetable shows today\'s periods and the full week', (tester) async {
    when(() => repository.getMyTimetable()).thenAnswer((_) async => const Result.success(_realTimetable));
    final provider = StudentTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Today (Monday)'), findsOneWidget);
    // findsWidgets: depending on the real clock the period can also show in
    // the "Up next" card.
    expect(find.textContaining('Science'), findsWidgets);
    expect(find.textContaining('Sam Teacher'), findsWidgets);
    expect(find.byType(DayStrip), findsOneWidget);
    expect(find.text('TUE'), findsOneWidget);

    await tester.tap(find.text('TUE'));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday Routine'), findsOneWidget);
    expect(find.text('No periods on this day'), findsOneWidget);
  });
}
