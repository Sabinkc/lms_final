import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_session.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_correction_repository.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/admin_attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/admin_attendance_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

class _MockAttendanceCorrectionRepository extends Mock implements AttendanceCorrectionRepository {}

const _session1 = AttendanceSessionSummary(
  id: 'sess1',
  className: 'Class 10',
  section: 'A',
  subject: 'General',
  date: '2026-08-23',
  presentCount: 8,
  absentCount: 1,
  lateCount: 1,
  totalCount: 10,
  locked: true,
);

Widget _wrap(AdminAttendanceProvider provider) => ChangeNotifierProvider<AdminAttendanceProvider>.value(
      value: provider,
      child: const MaterialApp(home: AdminAttendanceOverviewScreen()),
    );

void main() {
  late _MockAttendanceRepository attendanceRepository;
  late _MockAttendanceCorrectionRepository correctionRepository;

  setUp(() {
    attendanceRepository = _MockAttendanceRepository();
    correctionRepository = _MockAttendanceCorrectionRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) => Completer<Result<List<AttendanceSessionSummary>>>().future);
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state shows a message for a date with nothing submitted school-wide', (tester) async {
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) async => const Result.success([]));
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No attendance submitted on this date'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_session1]);
    });
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Class 10'), findsOneWidget);
  });

  testWidgets('success state lists sessions school-wide, filtering by the class text field', (tester) async {
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) async => const Result.success([_session1]));
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10 — A'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Class 10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    verify(() => attendanceRepository.getSessions(date: any(named: 'date'), className: 'Class 10', section: null))
        .called(1);
  });
}
