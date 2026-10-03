import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/department.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/department_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/department_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/departments_list_screen.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

const _department1 = Department(
  id: 'd1',
  name: 'Science',
  description: 'STEM subjects',
  headOfDepartmentId: 't1',
  headOfDepartmentName: 'Jane Teacher',
  classes: ['Class 10'],
  status: 'active',
);

const _teacher1 = Teacher(
  id: 't1',
  fullName: 'Jane Teacher',
  email: 'jane@test.dev',
  employeeId: 'EMP001',
  department: 'Science',
  designation: 'Senior Teacher',
  qualification: 'M.Sc.',
  subjects: ['Physics'],
  experience: 5,
  salary: 50000,
  address: '',
  phone: '',
  bankAccountNumber: '',
  status: 'active',
);

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: 'Grade 10', status: 'active');

Widget _wrap(DepartmentProvider provider) => ChangeNotifierProvider<DepartmentProvider>.value(
      value: provider,
      child: const MaterialApp(home: DepartmentsListScreen()),
    );

void main() {
  late _MockDepartmentRepository departmentRepository;
  late _MockTeacherRepository teacherRepository;
  late _MockClassRepository classRepository;

  setUp(() {
    departmentRepository = _MockDepartmentRepository();
    teacherRepository = _MockTeacherRepository();
    classRepository = _MockClassRepository();
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => departmentRepository.getDepartments())
        .thenAnswer((_) => Completer<Result<List<Department>>>().future);
    final provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the add-department CTA', (tester) async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([]));
    final provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No departments set up yet'), findsOneWidget);
    expect(find.text('Add Department'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_department1]);
    });
    final provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Science'), findsOneWidget);
  });

  testWidgets('success state lists departments with head and classes as a subtitle', (tester) async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    final provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Science'), findsOneWidget);
    expect(find.textContaining('Jane Teacher'), findsOneWidget);
    expect(find.textContaining('Class 10'), findsOneWidget);
  });

  testWidgets('add-department flow: FAB -> form -> save calls createDepartment and closes the dialog', (tester) async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([]));
    when(
      () => departmentRepository.createDepartment(
        name: any(named: 'name'),
        description: any(named: 'description'),
        headOfDepartmentId: any(named: 'headOfDepartmentId'),
        classes: any(named: 'classes'),
      ),
    ).thenAnswer((_) async => const Result.success(_department1));
    final provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Add Department'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Science');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => departmentRepository.createDepartment(
        name: 'Science',
        description: '',
        headOfDepartmentId: null,
        classes: [],
      ),
    ).called(1);
    expect(find.byType(FormSheet), findsNothing);
  });
}
