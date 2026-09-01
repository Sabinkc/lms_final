import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockExamRepository extends Mock implements ExamRepository {}

const _exam1 = Exam(
  id: 'e1',
  title: 'Mid Term',
  className: 'Class 10',
  section: 'A',
  subjects: [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
  examDate: '2026-09-01',
  status: 'upcoming',
);

void main() {
  late _MockExamRepository repository;
  late ExamProvider provider;

  setUp(() {
    repository = _MockExamRepository();
    provider = ExamProvider(repository);
  });

  test('loadExamsAsAdmin(): success populates exams and sets status', () async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([_exam1]));

    await provider.loadExamsAsAdmin();

    expect(provider.status, LoadStatus.success);
    expect(provider.exams, [_exam1]);
  });

  test('loadMyExams(): failure sets error status', () async {
    when(() => repository.getMyExams()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadMyExams();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('createExam(): success appends to the exams list and returns true', () async {
    when(() => repository.createExam(
          title: any(named: 'title'),
          className: any(named: 'className'),
          section: any(named: 'section'),
          subjects: any(named: 'subjects'),
          examDate: any(named: 'examDate'),
        )).thenAnswer((_) async => const Result.success(_exam1));

    final succeeded = await provider.createExam(
      title: 'Mid Term',
      className: 'Class 10',
      section: 'A',
      subjects: const [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
      examDate: '2026-09-01',
    );

    expect(succeeded, isTrue);
    expect(provider.exams, [_exam1]);
  });

  test('deleteExam(): success removes it from the exams list', () async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([_exam1]));
    await provider.loadExamsAsAdmin();
    when(() => repository.deleteExam(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteExam('e1');

    expect(succeeded, isTrue);
    expect(provider.exams, isEmpty);
  });
}
