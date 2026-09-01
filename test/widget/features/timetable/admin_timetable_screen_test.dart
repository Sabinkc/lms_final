import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/teacher_provider.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_day.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/admin_timetable_provider.dart';
import 'package:cloud_lms/features/timetable/presentation/screens/admin_timetable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active');
const _section1 = ClassSection(id: 'sec1', name: 'A', classId: 'c1', status: 'active');
const _teacher1 = Teacher(
  id: 'tch1',
  fullName: 'Jane Teacher',
  email: 'jane@test.dev',
  employeeId: 'EMP001',
  department: 'Science',
  designation: '',
  qualification: '',
  subjects: [],
  experience: 0,
  salary: 0,
  address: '',
  phone: '',
  bankAccountNumber: '',
  status: 'active',
);

Widget _wrap({
  required ClassRepository classRepository,
  required SectionRepository sectionRepository,
  required TeacherRepository teacherRepository,
  required TimetableRepository timetableRepository,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AcademicStructureProvider>(
          create: (_) => AcademicStructureProvider(classRepository, sectionRepository),
        ),
        ChangeNotifierProvider<TeacherProvider>(create: (_) => TeacherProvider(teacherRepository)),
        ChangeNotifierProvider<AdminTimetableProvider>(create: (_) => AdminTimetableProvider(timetableRepository)),
      ],
      child: const MaterialApp(home: AdminTimetableScreen()),
    );

void main() {
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;
  late _MockTeacherRepository teacherRepository;
  late _MockTimetableRepository timetableRepository;

  setUp(() {
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    teacherRepository = _MockTeacherRepository();
    timetableRepository = _MockTimetableRepository();
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async => const Result.success([_section1]));
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));
  });

  testWidgets('shows a prompt to pick a class and section before any is selected', (tester) async {
    await tester.pumpWidget(_wrap(
      classRepository: classRepository,
      sectionRepository: sectionRepository,
      teacherRepository: teacherRepository,
      timetableRepository: timetableRepository,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pick a class and section to view or edit its timetable'), findsOneWidget);
  });

  testWidgets('picking a class+section with no existing timetable shows all 6 empty weekdays', (tester) async {
    when(() => timetableRepository.getTimetables(className: any(named: 'className'), section: any(named: 'section'), type: any(named: 'type')))
        .thenAnswer((_) async => const Result.success([]));

    await tester.pumpWidget(_wrap(
      classRepository: classRepository,
      sectionRepository: sectionRepository,
      teacherRepository: teacherRepository,
      timetableRepository: timetableRepository,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Sunday'), findsNothing);
  });

  testWidgets('add a Monday period, fill it in, and save calls saveTimetable with that schedule', (tester) async {
    when(() => timetableRepository.getTimetables(className: any(named: 'className'), section: any(named: 'section'), type: any(named: 'type')))
        .thenAnswer((_) async => const Result.success([]));
    when(
      () => timetableRepository.saveTimetable(
        className: any(named: 'className'),
        section: any(named: 'section'),
        schedule: any(named: 'schedule'),
      ),
    ).thenAnswer((_) async => const Result.success(Timetable(
          id: 't1',
          className: 'Class 10',
          section: 'A',
          type: 'fixed',
          weekNumber: null,
          year: 2026,
          schedule: [],
        )));

    await tester.pumpWidget(_wrap(
      classRepository: classRepository,
      sectionRepository: sectionRepository,
      teacherRepository: teacherRepository,
      timetableRepository: timetableRepository,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    // Expand Monday, then add a period to it.
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add period').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Math');
    await tester.enterText(find.widgetWithText(TextField, 'Start'), '10:00 AM');
    await tester.enterText(find.widgetWithText(TextField, 'End'), '11:00 AM');

    await tester.ensureVisible(find.byIcon(Icons.save_outlined));
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    final captured = verify(
      () => timetableRepository.saveTimetable(
        className: 'Class 10',
        section: 'A',
        schedule: captureAny(named: 'schedule'),
      ),
    ).captured;
    final schedule = captured.single as List<TimetableDayInput>;
    expect(schedule, hasLength(1));
    expect(schedule.single.day, 'Monday');
    expect(schedule.single.periods.single.subject, 'Math');
    expect(schedule.single.periods.single.startTime, '10:00 AM');
  });
}
