import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/teacher_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/teachers_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockTeacherRepository extends Mock implements TeacherRepository {}

const _teacher1 = Teacher(
  id: 't1',
  fullName: 'Jane Teacher',
  email: 'jane@school.test',
  employeeId: 'EMP001',
  department: 'Science',
  designation: 'Lecturer',
  qualification: '',
  subjects: [],
  experience: 0,
  salary: 0,
  address: '',
  phone: '',
  bankAccountNumber: '',
  status: 'active',
);

Widget _wrap(TeacherProvider provider) => ChangeNotifierProvider<TeacherProvider>.value(
      value: provider,
      child: const MaterialApp(home: TeachersListScreen()),
    );

void main() {
  late _MockTeacherRepository repository;

  setUp(() {
    repository = _MockTeacherRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getTeachers()).thenAnswer((_) => Completer<Result<List<Teacher>>>().future);
    final provider = TeacherProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state shows the CTA', (tester) async {
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([]));
    final provider = TeacherProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No teachers added yet'), findsOneWidget);
    expect(find.text('Add Teacher'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getTeachers()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_teacher1]);
    });
    final provider = TeacherProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Jane Teacher'), findsOneWidget);
  });

  testWidgets('success state lists teachers and search filters them', (tester) async {
    const teacher2 = Teacher(
      id: 't2',
      fullName: 'Mark Maths',
      email: 'mark@school.test',
      employeeId: 'EMP002',
      department: 'Mathematics',
      designation: 'Lecturer',
      qualification: '',
      subjects: [],
      experience: 0,
      salary: 0,
      address: '',
      phone: '',
      bankAccountNumber: '',
      status: 'active',
    );
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1, teacher2]));
    final provider = TeacherProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Jane Teacher'), findsOneWidget);
    expect(find.text('Mark Maths'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Jane');
    await tester.pumpAndSettle();

    expect(find.text('Jane Teacher'), findsOneWidget);
    expect(find.text('Mark Maths'), findsNothing);
  });

  testWidgets('add-teacher flow: FAB -> form -> save calls createTeacher and closes the dialog', (tester) async {
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([]));
    when(() => repository.createTeacher(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          employeeId: any(named: 'employeeId'),
          department: any(named: 'department'),
          password: any(named: 'password'),
          designation: any(named: 'designation'),
          qualification: any(named: 'qualification'),
          subjects: any(named: 'subjects'),
          experience: any(named: 'experience'),
          salary: any(named: 'salary'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          bankAccountNumber: any(named: 'bankAccountNumber'),
        )).thenAnswer((_) async => const Result.success(_teacher1));
    final provider = TeacherProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Teacher'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Jane Teacher');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@school.test');
    await tester.enterText(find.widgetWithText(TextFormField, 'Employee ID'), 'EMP001');
    await tester.enterText(find.widgetWithText(TextFormField, 'Department'), 'Science');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => repository.createTeacher(
          fullName: 'Jane Teacher',
          email: 'jane@school.test',
          employeeId: 'EMP001',
          department: 'Science',
          password: any(named: 'password'),
          designation: any(named: 'designation'),
          qualification: any(named: 'qualification'),
          subjects: any(named: 'subjects'),
          experience: any(named: 'experience'),
          salary: any(named: 'salary'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          bankAccountNumber: any(named: 'bankAccountNumber'),
        )).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
