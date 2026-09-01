import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_submit_result.dart';
import 'package:cloud_lms/features/attendance/data/models/teacher_section.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/mark_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _section1 = TeacherSection(id: 'sec1', name: 'A', classId: 'c1', className: 'Class 10');

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

Widget _wrap(AttendanceProvider provider) => ChangeNotifierProvider<AttendanceProvider>.value(
      value: provider,
      child: const MaterialApp(home: MarkAttendanceScreen()),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<AttendanceRecordInput>[]);
  });

  late _MockAttendanceRepository repository;

  setUp(() {
    repository = _MockAttendanceRepository();
  });

  testWidgets('loading state shows a progress indicator over the section picker', (tester) async {
    when(() => repository.getMySections()).thenAnswer((_) => Completer<Result<List<TeacherSection>>>().future);
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a section picker and prompts to pick one before showing a roster', (tester) async {
    when(() => repository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Pick a section to load its roster'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('picking a section loads its roster, defaulting every student to Present', (tester) async {
    when(() => repository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));
    when(() => repository.getSectionRoster('sec1')).thenAnswer((_) async => const Result.success([_student1]));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10 — A').last);
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
  });

  testWidgets('submit flow: change a status, submit, and the bar shows the locked confirmation', (tester) async {
    when(() => repository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));
    when(() => repository.getSectionRoster('sec1')).thenAnswer((_) async => const Result.success([_student1]));
    when(() => repository.markAttendance(
          sectionId: any(named: 'sectionId'),
          date: any(named: 'date'),
          subject: any(named: 'subject'),
          records: any(named: 'records'),
        )).thenAnswer((_) async => const Result.success(AttendanceSubmitResult(savedCount: 1, failed: [])));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10 — A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit attendance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Attendance submitted and locked'), findsOneWidget);
    verify(() => repository.markAttendance(
          sectionId: 'sec1',
          date: any(named: 'date'),
          subject: any(named: 'subject'),
          records: any(named: 'records'),
        )).called(1);
  });

  testWidgets('a duplicate-submission failure surfaces the backend message without locking the screen',
      (tester) async {
    when(() => repository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));
    when(() => repository.getSectionRoster('sec1')).thenAnswer((_) async => const Result.success([_student1]));
    when(() => repository.markAttendance(
          sectionId: any(named: 'sectionId'),
          date: any(named: 'date'),
          subject: any(named: 'subject'),
          records: any(named: 'records'),
        )).thenAnswer((_) async => const Result.failure(ServerException('Attendance has already been submitted.')));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10 — A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit attendance'));
    await tester.pumpAndSettle();

    expect(find.text('Attendance has already been submitted.'), findsOneWidget);
    expect(find.text('Submit attendance'), findsOneWidget);
  });
}
