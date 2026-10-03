import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/parent.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/parent_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/parent_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/parents_list_screen.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockParentRepository extends Mock implements ParentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

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

const _parent1 = Parent(
  id: 'p1',
  fullName: 'Pat Parent',
  email: 'pat@school.test',
  occupation: 'Engineer',
  address: '',
  phone: '',
  status: 'active',
  children: [_student1],
);

Widget _wrap(ParentProvider provider) => ChangeNotifierProvider<ParentProvider>.value(
      value: provider,
      child: const MaterialApp(home: ParentsListScreen()),
    );

void main() {
  late _MockParentRepository parentRepository;
  late _MockStudentRepository studentRepository;

  setUp(() {
    parentRepository = _MockParentRepository();
    studentRepository = _MockStudentRepository();
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([]));
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => parentRepository.getParents()).thenAnswer((_) => Completer<Result<List<Parent>>>().future);
    final provider = ParentProvider(parentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the CTA', (tester) async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([]));
    final provider = ParentProvider(parentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No parents added yet'), findsOneWidget);
    expect(find.text('Add Parent'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => parentRepository.getParents()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_parent1]);
    });
    final provider = ParentProvider(parentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Pat Parent'), findsOneWidget);
  });

  testWidgets('success state lists parents with their linked children', (tester) async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([_parent1]));
    final provider = ParentProvider(parentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Pat Parent'), findsOneWidget);
    expect(find.text('Children: Sam Student'), findsOneWidget);
  });

  testWidgets('add-parent flow: FAB -> form -> select a child -> save calls createParent', (tester) async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([]));
    when(() => parentRepository.createParent(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          occupation: any(named: 'occupation'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          studentIds: any(named: 'studentIds'),
        )).thenAnswer((_) async => const Result.success(_parent1));
    final provider = ParentProvider(parentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Add Parent'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Pat Parent');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'pat@school.test');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Sam Student'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => parentRepository.createParent(
          fullName: 'Pat Parent',
          email: 'pat@school.test',
          password: any(named: 'password'),
          occupation: any(named: 'occupation'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          studentIds: ['s1'],
        )).called(1);
    expect(find.byType(FormSheet), findsNothing);
  });
}
