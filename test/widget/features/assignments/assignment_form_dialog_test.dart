import 'package:cloud_lms/core/di/service_locator.dart';
import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/assignments/data/models/assignment.dart';
import 'package:cloud_lms/features/assignments/data/repositories/assignment_repository.dart';
import 'package:cloud_lms/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:cloud_lms/features/assignments/presentation/screens/assignment_form_dialog.dart';
import 'package:cloud_lms/features/attendance/data/models/teacher_section.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAssignmentRepository extends Mock implements AssignmentRepository {}

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _section1 = TeacherSection(id: 'sec1', name: 'A', classId: 'c1', className: 'Class 10');

const _created = Assignment(
  id: 'a1',
  title: 'Algebra Homework',
  description: 'Chapter 4 exercises',
  className: 'Class 10',
  section: 'A',
  subject: 'Math',
  dueDate: '2026-09-01',
  attachment: '',
  status: 'active',
  teacherEmployeeId: 'EMP001',
);

void main() {
  late _MockAssignmentRepository assignmentRepository;
  late _MockAttendanceRepository attendanceRepository;

  setUp(() {
    assignmentRepository = _MockAssignmentRepository();
    attendanceRepository = _MockAttendanceRepository();
    when(() => attendanceRepository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));
    if (sl.isRegistered<AttendanceRepository>()) sl.unregister<AttendanceRepository>();
    sl.registerSingleton<AttendanceRepository>(attendanceRepository);
  });

  tearDown(() {
    if (sl.isRegistered<AttendanceRepository>()) sl.unregister<AttendanceRepository>();
  });

  testWidgets('picking class/section/date and saving calls createAssignment with the right values', (tester) async {
    when(() => assignmentRepository.createAssignment(
          title: any(named: 'title'),
          description: any(named: 'description'),
          className: any(named: 'className'),
          section: any(named: 'section'),
          subject: any(named: 'subject'),
          dueDate: any(named: 'dueDate'),
        )).thenAnswer((_) async => const Result.success(_created));

    final assignmentProvider = AssignmentProvider(assignmentRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AssignmentProvider>.value(value: assignmentProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAssignmentFormDialog(context, assignmentProvider),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Add Assignment'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Algebra Homework');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Chapter 4 exercises');
    await tester.enterText(find.widgetWithText(TextFormField, 'Subject'), 'Math');

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

    verify(() => assignmentRepository.createAssignment(
          title: 'Algebra Homework',
          description: 'Chapter 4 exercises',
          className: 'Class 10',
          section: 'A',
          subject: 'Math',
          dueDate: any(named: 'dueDate'),
        )).called(1);
    expect(find.byType(FormSheet), findsNothing);
  });

  testWidgets('a failed section load shows an inline error instead of a silently empty dropdown', (tester) async {
    when(() => attendanceRepository.getMySections())
        .thenAnswer((_) async => const Result.failure(ServerException('boom')));

    final assignmentProvider = AssignmentProvider(assignmentRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AssignmentProvider>.value(value: assignmentProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAssignmentFormDialog(context, assignmentProvider),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load your classes'), findsOneWidget);
  });

  testWidgets('edit mode shows class/section read-only and calls updateAssignment, not createAssignment',
      (tester) async {
    const updated = Assignment(
      id: 'a1',
      title: 'Algebra Homework (updated)',
      description: 'Chapter 4 exercises',
      className: 'Class 10',
      section: 'A',
      subject: 'Math',
      dueDate: '2026-09-01',
      attachment: '',
      status: 'active',
      teacherEmployeeId: 'EMP001',
    );
    when(() => assignmentRepository.updateAssignment(
          id: any(named: 'id'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          subject: any(named: 'subject'),
          dueDate: any(named: 'dueDate'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => const Result.success(updated));

    final assignmentProvider = AssignmentProvider(assignmentRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AssignmentProvider>.value(value: assignmentProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAssignmentFormDialog(context, assignmentProvider, existing: _created),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Edit Assignment'), findsOneWidget);
    expect(find.text('Class Class 10 · Section A'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    verifyNever(() => attendanceRepository.getMySections());

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Algebra Homework (updated)');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => assignmentRepository.updateAssignment(
          id: 'a1',
          title: 'Algebra Homework (updated)',
          description: any(named: 'description'),
          subject: any(named: 'subject'),
          dueDate: any(named: 'dueDate'),
          status: any(named: 'status'),
        )).called(1);
    verifyNever(() => assignmentRepository.createAssignment(
          title: any(named: 'title'),
          description: any(named: 'description'),
          className: any(named: 'className'),
          section: any(named: 'section'),
          subject: any(named: 'subject'),
          dueDate: any(named: 'dueDate'),
        ));
  });
}
