import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_result_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_result_provider.dart';
import 'package:cloud_lms/features/exams/presentation/screens/publish_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockExamResultRepository extends Mock implements ExamResultRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _exam1 = Exam(
  id: 'e1',
  title: 'Mid Term',
  className: 'Class 10',
  section: 'A',
  subjects: [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
  examDate: '2026-09-01',
  status: 'upcoming',
);

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

Widget _wrap(ExamResultProvider provider) => ChangeNotifierProvider<ExamResultProvider>.value(
      value: provider,
      child: const MaterialApp(home: PublishResultsScreen(exam: _exam1)),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<StudentResultInput>[]);
  });

  late _MockExamResultRepository repository;
  late _MockStudentRepository studentRepository;

  setUp(() {
    repository = _MockExamResultRepository();
    studentRepository = _MockStudentRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) => Completer<Result<List<Student>>>().future);
    final provider = ExamResultProvider(repository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('roster loads and entering a mark then publishing calls publishResults', (tester) async {
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student1]));
    when(() => repository.publishResults(examId: any(named: 'examId'), results: any(named: 'results')))
        .thenAnswer((_) async => const Result.success(null));
    final provider = ExamResultProvider(repository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '85');
    await tester.tap(find.ancestor(of: find.text('Publish Results'), matching: find.bySubtype<FilledButton>()));
    await tester.pumpAndSettle();

    final captured = verify(() => repository.publishResults(examId: 'e1', results: captureAny(named: 'results')))
        .captured
        .single as List<StudentResultInput>;
    expect(captured.single.studentId, 's1');
    expect(captured.single.marks.single.obtainedMarks, 85);
    expect(find.text('Results published.'), findsOneWidget);
  });
}
