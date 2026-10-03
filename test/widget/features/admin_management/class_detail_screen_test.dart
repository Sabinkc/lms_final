import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/teacher_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/class_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

Student _student(String id, String name, String className, String section) => Student(
      id: id,
      fullName: name,
      email: '$id@school.test',
      admissionNumber: 'ADM$id',
      rollNumber: id,
      className: className,
      section: section,
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );

Teacher _teacher(String id, String name, List<String> subjects) => Teacher(
      id: id,
      fullName: name,
      email: '$id@school.test',
      employeeId: 'T$id',
      department: '',
      designation: '',
      qualification: '',
      subjects: subjects,
      experience: 0,
      salary: 0,
      address: '',
      phone: '',
      bankAccountNumber: '',
      status: 'active',
    );

void main() {
  testWidgets('shows real counts, section teachers and students, and switches tabs', (tester) async {
    final classRepository = _MockClassRepository();
    final sectionRepository = _MockSectionRepository();
    final studentRepository = _MockStudentRepository();
    final teacherRepository = _MockTeacherRepository();

    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([
          AcademicClass(id: 'c1', name: 'Class 10', description: 'Science', status: 'active', sectionCount: 2),
        ]));
    when(() => sectionRepository.getSections('c1')).thenAnswer((_) async => const Result.success([
          ClassSection(id: 'sa', name: 'A', classId: 'c1', status: 'active', teacherIds: ['t1']),
          ClassSection(id: 'sb', name: 'B', classId: 'c1', status: 'active', teacherIds: ['t1']),
        ]));
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => Result.success([
              _student('1', 'Sam Student', 'Class 10', 'A'),
              _student('2', 'Amy Student', 'Class 10', 'B'),
              _student('3', 'Other Kid', 'Class 9', 'A'),
            ]));
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => Result.success([
          _teacher('t1', 'Anita Sharma', ['Mathematics']),
          _teacher('t2', 'Not Assigned', ['Science']),
        ]));

    // Phone-shaped and tall enough that the Overview's lazily-built cards
    // are all on screen.
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final academic = AcademicStructureProvider(classRepository, sectionRepository);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: academic),
        ChangeNotifierProvider.value(value: StudentProvider(studentRepository, classRepository, sectionRepository)),
        ChangeNotifierProvider.value(value: TeacherProvider(teacherRepository)),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const ClassDetailScreen(classId: 'c1'))]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Class 10'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('2 Students'), findsOneWidget);
    expect(find.text('2 Sections'), findsOneWidget);
    // Teacher assigned to both sections counts once; unassigned teacher absent.
    expect(find.text('Assigned Teacher'), findsOneWidget);
    expect(find.text('Anita Sharma'), findsOneWidget);
    expect(find.text('Not Assigned'), findsNothing);
    // Other classes' students are not listed.
    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Other Kid'), findsNothing);
    // No fabricated attendance rate.
    expect(find.textContaining('Attendance'), findsNothing);

    await tester.tap(find.text('Students').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Roll 2'), findsOneWidget);

    await tester.tap(find.text('Sections').last);
    await tester.pumpAndSettle();
    expect(find.text('Add Section'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('a failed teachers load shows a retry notice instead of spinning forever', (tester) async {
    final classRepository = _MockClassRepository();
    final sectionRepository = _MockSectionRepository();
    final studentRepository = _MockStudentRepository();
    final teacherRepository = _MockTeacherRepository();

    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([
          AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active', sectionCount: 1),
        ]));
    when(() => sectionRepository.getSections('c1')).thenAnswer((_) async => const Result.success([
          ClassSection(id: 'sa', name: 'A', classId: 'c1', status: 'active', teacherIds: ['t1']),
        ]));
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AcademicStructureProvider(classRepository, sectionRepository)),
        ChangeNotifierProvider.value(value: StudentProvider(studentRepository, classRepository, sectionRepository)),
        ChangeNotifierProvider.value(value: TeacherProvider(teacherRepository)),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const ClassDetailScreen(classId: 'c1'))]),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Some details couldn't load."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  test('ClassSection reads teacher ids from populated objects and bare strings', () {
    final populated = ClassSection.fromJson({
      '_id': 's1',
      'teachers': [
        {'_id': 't1', 'employeeId': 'T002'},
      ],
    });
    final bare = ClassSection.fromJson({
      '_id': 's2',
      'teachers': ['t2'],
    });
    expect(populated.teacherIds, ['t1']);
    expect(bare.teacherIds, ['t2']);
  });
}
