import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/classes_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: 'Grade 10', status: 'active');

Student _student(String id, String className) => Student(
      id: id,
      fullName: 'Student $id',
      email: '$id@school.test',
      admissionNumber: id,
      rollNumber: '1',
      className: className,
      section: 'A',
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );

late StudentProvider _studentProvider;

Widget _wrap(AcademicStructureProvider provider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AcademicStructureProvider>.value(value: provider),
        ChangeNotifierProvider<StudentProvider>.value(value: _studentProvider),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const ClassesListScreen()),
            GoRoute(path: '/admin/classes/:classId', builder: (context, state) => const SizedBox()),
          ],
        ),
      ),
    );

void main() {
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;

  late _MockStudentRepository studentRepository;

  setUp(() {
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    studentRepository = _MockStudentRepository();
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => Result.success([_student('s1', 'Class 10'), _student('s2', 'Class 10')]));
    _studentProvider = StudentProvider(studentRepository, classRepository, sectionRepository);
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => classRepository.getClasses()).thenAnswer((_) => Completer<Result<List<AcademicClass>>>().future);
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state shows the CTA from docs/screens.md', (tester) async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([]));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No classes set up yet'), findsOneWidget);
    expect(find.text('Add Class'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => classRepository.getClasses()).thenAnswer((_) async {
      callCount++;
      return callCount == 1
          ? const Result.failure(NetworkException())
          : const Result.success([_class1]);
    });
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Class 10'), findsOneWidget);
  });

  testWidgets('success state lists classes and search filters them', (tester) async {
    const class2 = AcademicClass(id: 'c2', name: 'Class 9', description: '', status: 'active');
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1, class2]));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10'), findsOneWidget);
    expect(find.text('Class 9'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '10');
    await tester.pumpAndSettle();

    expect(find.text('Class 10'), findsOneWidget);
    expect(find.text('Class 9'), findsNothing);
  });

  testWidgets('each class shows its student and section counts', (tester) async {
    const class10 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active', sectionCount: 1);
    const class9 = AcademicClass(id: 'c2', name: 'Class 9', description: '', status: 'active', sectionCount: 3);
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([class10, class9]));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('2 Students'), findsOneWidget);
    expect(find.text('1 Section'), findsOneWidget);
    expect(find.text('0 Students'), findsOneWidget);
    expect(find.text('3 Sections'), findsOneWidget);
    // Badge shows the class number, as in the reference.
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('add-class flow: app-bar button -> form -> save calls createClass and closes the dialog', (tester) async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([]));
    when(() => classRepository.createClass(name: any(named: 'name'), description: any(named: 'description')))
        .thenAnswer((_) async => const Result.success(_class1));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    // First match is the app-bar button (the empty state has its own below).
    await tester.tap(find.text('Add Class').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Class'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Class 10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => classRepository.createClass(name: 'Class 10', description: '')).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
