import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/attendance/data/models/student_attendance_history.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/self_attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/my_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _history = StudentAttendanceHistory(
  studentName: 'Sam Student',
  summary: AttendanceHistorySummary(present: 8, absent: 1, late: 1, leave: 0, halfDay: 0, total: 10, percentage: 90),
  records: [
    AttendanceRecordDetail(
      id: 'rec1',
      status: 'present',
      remarks: '',
      date: '2026-08-23',
      subject: 'General',
      className: 'Class 10',
      section: 'A',
    ),
  ],
);

Widget _wrap(SelfAttendanceProvider provider) => ChangeNotifierProvider<SelfAttendanceProvider>.value(
      value: provider,
      child: const MaterialApp(home: MyAttendanceScreen()),
    );

void main() {
  late _MockAttendanceRepository repository;

  setUp(() {
    repository = _MockAttendanceRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getMyStudentId()).thenAnswer((_) => Completer<Result<String>>().future);
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows the failure message with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getMyStudentId()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success('s1');
    });
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('success state shows the summary card and the record list', (tester) async {
    when(() => repository.getMyStudentId()).thenAnswer((_) async => const Result.success('s1'));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('90%'), findsOneWidget);
    expect(find.text('2026-08-23 — General'), findsOneWidget);
  });

  testWidgets('empty state shows a message when there are no records yet', (tester) async {
    when(() => repository.getMyStudentId()).thenAnswer((_) async => const Result.success('s1'));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer(
      (_) async => const Result.success(StudentAttendanceHistory(
        studentName: 'Sam Student',
        summary: AttendanceHistorySummary(present: 0, absent: 0, late: 0, leave: 0, halfDay: 0, total: 0, percentage: 0),
        records: [],
      )),
    );
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No attendance recorded yet'), findsOneWidget);
  });
}
