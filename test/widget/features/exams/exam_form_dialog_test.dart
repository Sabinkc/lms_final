import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_provider.dart';
import 'package:cloud_lms/features/exams/presentation/screens/exam_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockExamRepository extends Mock implements ExamRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active');
const _section1 = ClassSection(id: 'sec1', name: 'A', classId: 'c1', status: 'active');

const _created = Exam(
  id: 'e1',
  title: 'Mid Term',
  className: 'Class 10',
  section: 'A',
  subjects: [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
  examDate: '2026-09-01',
  status: 'upcoming',
);

void main() {
  setUpAll(() {
    registerFallbackValue(<ExamSubject>[]);
  });

  late _MockExamRepository examRepository;
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;

  setUp(() {
    examRepository = _MockExamRepository();
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async => const Result.success([_section1]));
  });

  testWidgets('filling class/section/subject and saving calls createExam with one subject', (tester) async {
    when(() => examRepository.createExam(
          title: any(named: 'title'),
          className: any(named: 'className'),
          section: any(named: 'section'),
          subjects: any(named: 'subjects'),
          examDate: any(named: 'examDate'),
        )).thenAnswer((_) async => const Result.success(_created));

    final examProvider = ExamProvider(examRepository);
    final academicProvider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ExamProvider>.value(value: examProvider),
          ChangeNotifierProvider<AcademicStructureProvider>.value(value: academicProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showExamFormDialog(context, examProvider),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Exam'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Mid Term');

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Subject'), 'Math');
    // Full/Pass marks already default to 100/40 via the dialog's controllers.

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final captured = verify(() => examRepository.createExam(
          title: 'Mid Term',
          className: 'Class 10',
          section: 'A',
          subjects: captureAny(named: 'subjects'),
          examDate: any(named: 'examDate'),
        )).captured;
    expect(captured, hasLength(1));
    final subjects = captured.single as List<ExamSubject>;
    expect(subjects.single.name, 'Math');
    expect(subjects.single.fullMarks, 100);
    expect(subjects.single.passMarks, 40);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Add subject appends a second subject row', (tester) async {
    final examProvider = ExamProvider(examRepository);
    final academicProvider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ExamProvider>.value(value: examProvider),
          ChangeNotifierProvider<AcademicStructureProvider>.value(value: academicProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showExamFormDialog(context, examProvider),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Subject'), findsOneWidget);

    await tester.ensureVisible(find.text('Add subject'));
    await tester.tap(find.text('Add subject'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Subject'), findsNWidgets(2));
  });
}
