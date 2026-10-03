import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_day_attendance_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_provider.dart';
import 'package:cloud_lms/features/attendance/data/models/day_attendance_record.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/students_list_screen.dart';
import 'package:cloud_lms/shared/widgets/filter_chip_bar.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

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

late StudentDayAttendanceProvider _dayAttendance;

Widget _wrap(StudentProvider provider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<StudentProvider>.value(value: provider),
        ChangeNotifierProvider<StudentDayAttendanceProvider>.value(value: _dayAttendance),
      ],
      child: const MaterialApp(home: StudentsListScreen()),
    );

void main() {
  late _MockStudentRepository studentRepository;
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;

  setUp(() {
    studentRepository = _MockStudentRepository();
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([]));
    final attendanceRepository = _MockAttendanceRepository();
    when(() => attendanceRepository.getDayRecords(date: any(named: 'date'), className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([
              DayAttendanceRecord(date: '2026-10-01', status: 'absent', studentName: 'Sam Student', className: 'Class 10 A'),
            ]));
    _dayAttendance = StudentDayAttendanceProvider(attendanceRepository);
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) => Completer<Result<List<Student>>>().future);
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the CTA', (tester) async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([]));
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No students added yet'), findsOneWidget);
    expect(find.text('Add Student'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => studentRepository.getStudents(className: any(named: 'className'))).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_student1]);
    });
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsOneWidget);
  });

  testWidgets('success state lists students and search filters them', (tester) async {
    const student2 = Student(
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
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1, student2]));
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Alex Other'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sam');
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Alex Other'), findsNothing);
  });

  testWidgets('class filter chips appear once classOptions load and filtering re-queries the repository',
      (tester) async {
    const class1 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active');
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([class1]));
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10'), findsWidgets);

    await tester.tap(find.widgetWithText(AppFilterChip, 'Class 10'));
    await tester.pumpAndSettle();

    verify(() => studentRepository.getStudents(className: 'Class 10')).called(1);
  });

  testWidgets('add-student flow: FAB -> pick class/section -> save calls createStudent', (tester) async {
    const class1 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active');
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([class1]));
    when(() => sectionRepository.getSections('c1')).thenAnswer(
      (_) async => const Result.success([ClassSection(id: 'sec1', name: 'A', classId: 'c1', status: 'active')]),
    );
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => studentRepository.createStudent(
          className: any(named: 'className'),
          section: any(named: 'section'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          userId: any(named: 'userId'),
          password: any(named: 'password'),
          admissionNumber: any(named: 'admissionNumber'),
          rollNumber: any(named: 'rollNumber'),
          parentId: any(named: 'parentId'),
          dob: any(named: 'dob'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
        )).thenAnswer((_) async => const Result.success(_student1));
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Add Student'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Sam Student');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'sam@school.test');

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => studentRepository.createStudent(
          className: 'Class 10',
          section: 'A',
          fullName: 'Sam Student',
          email: 'sam@school.test',
          userId: any(named: 'userId'),
          password: any(named: 'password'),
          admissionNumber: any(named: 'admissionNumber'),
          rollNumber: any(named: 'rollNumber'),
          parentId: any(named: 'parentId'),
          dob: any(named: 'dob'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
        )).called(1);
    expect(find.byType(FormSheet), findsNothing);
  });

  testWidgets('each student shows that day\'s attendance, matched by name and class', (tester) async {
    const other = Student(
      id: 's2',
      fullName: 'Alex Other',
      email: '',
      admissionNumber: '',
      rollNumber: '',
      className: 'Class 10',
      section: 'A',
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1, other]));
    final provider = StudentProvider(studentRepository, classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Absent'), findsWidgets); // Sam's pill + the Absent stat tile
    expect(find.text('Not marked'), findsOneWidget); // Alex has no record that day
    expect(find.text('(50.0%)'), findsOneWidget); // 1 of 2 absent
  });
}
