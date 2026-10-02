import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/timetable/data/models/teacher_schedule_entry.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/teacher_timetable_provider.dart';
import 'package:cloud_lms/features/timetable/presentation/screens/teacher_timetable_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _entry1 = TeacherScheduleEntry(
  className: 'Class 10',
  section: 'A',
  type: 'fixed',
  day: 'Monday',
  periods: [
    TimetablePeriod(periodNumber: 1, subject: 'Math', teacherId: null, teacherName: null, startTime: '10:00 AM', endTime: '11:00 AM', room: '101'),
  ],
);

Widget _wrap(TeacherTimetableProvider provider) => ChangeNotifierProvider<TeacherTimetableProvider>.value(
      value: provider,
      child: const MaterialApp(home: TeacherTimetableScreen()),
    );

void main() {
  late _MockTimetableRepository repository;

  setUp(() {
    repository = _MockTimetableRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getTeacherTimetable()).thenAnswer((_) => Completer<Result<List<TeacherScheduleEntry>>>().future);
    final provider = TeacherTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows a message', (tester) async {
    when(() => repository.getTeacherTimetable()).thenAnswer((_) async => const Result.success([]));
    final provider = TeacherTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No periods scheduled for you yet'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getTeacherTimetable()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_entry1]);
    });
    final provider = TeacherTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Class 10'), findsOneWidget);
  });

  testWidgets('success state shows the day/class/section header and each period', (tester) async {
    when(() => repository.getTeacherTimetable()).thenAnswer((_) async => const Result.success([_entry1]));
    final provider = TeacherTimetableProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.textContaining('Monday'), findsOneWidget);
    expect(find.textContaining('Class 10 A'), findsOneWidget);
    expect(find.textContaining('Math'), findsOneWidget);
  });
}
