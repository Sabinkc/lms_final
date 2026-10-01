import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/attendance/data/models/student_attendance_history.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/self_attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/child_attendance_screen.dart';
import 'package:cloud_lms/shared/widgets/filter_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@school.test',
  admissionNumber: 'ADM001',
  rollNumber: '1',
  className: 'Class 10',
  section: 'A',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

const _student2 = Student(
  id: 's2',
  fullName: 'Alex Other',
  email: 'alex@school.test',
  admissionNumber: 'ADM002',
  rollNumber: '2',
  className: 'Class 9',
  section: 'B',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

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
      child: const MaterialApp(home: ChildAttendanceScreen()),
    );

void main() {
  late _MockAttendanceRepository repository;

  setUp(() {
    repository = _MockAttendanceRepository();
  });

  testWidgets('loading state shows a progress indicator', (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) => Completer<Result<List<Student>>>().future);
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('no linked children shows a message, no crash', (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([]));
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No children linked to your account yet'), findsOneWidget);
  });

  testWidgets('a single child auto-loads with no selector chips shown', (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1]));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byType(AppFilterChip), findsNothing);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('multiple children show selector chips; tapping one loads that child\'s history', (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));
    final provider = SelfAttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byType(AppFilterChip), findsNWidgets(2));
    expect(find.text('Select a child above to view their attendance'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppFilterChip, 'Alex Other'));
    await tester.pumpAndSettle();

    verify(() => repository.getStudentAttendanceHistory(
          studentId: 's2',
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).called(1);
    expect(find.text('90%'), findsOneWidget);
  });
}
