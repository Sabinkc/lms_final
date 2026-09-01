import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/models/exam_result.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_result_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_result_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

const _student2 = Student(
  id: 's2',
  fullName: 'Alex Other',
  email: 'alex@school.test',
  admissionNumber: 'ADM002',
  rollNumber: '2',
  className: 'Class 10',
  section: 'A',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

const _result1 = ExamResult(
  id: 'r1',
  examId: 'e1',
  examTitle: 'Mid Term',
  studentId: 's1',
  studentName: 'Sam Student',
  studentAdmissionNumber: 'ADM001',
  marks: [ExamResultMark(subject: 'Math', fullMarks: 100, passMarks: 40, obtainedMarks: 85, isPassed: true, grade: 'A')],
  totalObtained: 85,
  totalFull: 100,
  percentage: 85,
  grade: 'A',
  isPassed: true,
  rank: 1,
  remarks: '',
);

void main() {
  setUpAll(() {
    registerFallbackValue(<StudentResultInput>[]);
  });

  late _MockExamResultRepository repository;
  late _MockStudentRepository studentRepository;
  late ExamResultProvider provider;

  setUp(() {
    repository = _MockExamResultRepository();
    studentRepository = _MockStudentRepository();
    provider = ExamResultProvider(repository, studentRepository);
  });

  test('loadRosterForExam(): fetches the roster filtered by the exam\'s class/section', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student1, _student2]));

    await provider.loadRosterForExam(_exam1);

    expect(provider.rosterStatus, LoadStatus.success);
    expect(provider.roster, [_student1, _student2]);
    verify(() => studentRepository.getStudents(className: 'Class 10', section: 'A')).called(1);
  });

  test('setMark() then publish(): only sends students/subjects that actually got a mark entered', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student1, _student2]));
    await provider.loadRosterForExam(_exam1);

    provider.setMark('s1', 'Math', 85);
    // s2 gets no mark at all — should be excluded from the publish payload.

    when(() => repository.publishResults(examId: any(named: 'examId'), results: captureAny(named: 'results')))
        .thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.publish(_exam1);

    expect(succeeded, isTrue);
    expect(provider.published, isTrue);
    final captured = verify(() => repository.publishResults(examId: 'e1', results: captureAny(named: 'results')))
        .captured
        .single as List<StudentResultInput>;
    expect(captured, hasLength(1));
    expect(captured.single.studentId, 's1');
    expect(captured.single.marks.single.obtainedMarks, 85);
  });

  test('publish(): failure surfaces the error and leaves published false', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student1]));
    await provider.loadRosterForExam(_exam1);
    provider.setMark('s1', 'Math', 85);
    when(() => repository.publishResults(examId: any(named: 'examId'), results: any(named: 'results')))
        .thenAnswer((_) async => const Result.failure(ServerException()));

    final succeeded = await provider.publish(_exam1);

    expect(succeeded, isFalse);
    expect(provider.published, isFalse);
    expect(provider.publishError, isA<ServerException>());
  });

  test('loadClassResults(): success populates summary and ranked results', () async {
    const summary = ClassResultsSummary(total: 1, passed: 1, failed: 0, avgPercentage: 85, gradeDistribution: {'A': 1});
    when(() => repository.getExamResults(any())).thenAnswer((_) async => const Result.success((summary, [_result1])));

    await provider.loadClassResults('e1');

    expect(provider.classResultsStatus, LoadStatus.success);
    expect(provider.classSummary, summary);
    expect(provider.classResults, [_result1]);
  });

  test('loadMyResultForExam(): success populates myExamResult', () async {
    when(() => repository.getMyResultForExam(any())).thenAnswer((_) async => const Result.success(_result1));

    await provider.loadMyResultForExam('e1');

    expect(provider.myExamResultStatus, LoadStatus.success);
    expect(provider.myExamResult, _result1);
  });

  test('loadChildren(): with one child, auto-selects and loads their results', () async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1]));
    const summary = ResultsSummary(totalExams: 1, passed: 1, failed: 0, averagePercentage: 85);
    when(() => repository.getChildResultsSummary(any())).thenAnswer((_) async => const Result.success(summary));
    when(() => repository.getChildResults(any())).thenAnswer((_) async => const Result.success([_result1]));

    await provider.loadChildren();

    expect(provider.selectedChildId, 's1');
    expect(provider.childResultsStatus, LoadStatus.success);
    expect(provider.childResults, [_result1]);
  });

  test('selectChild(): loads the chosen child\'s results', () async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));
    await provider.loadChildren();
    const summary = ResultsSummary(totalExams: 1, passed: 1, failed: 0, averagePercentage: 85);
    when(() => repository.getChildResultsSummary(any())).thenAnswer((_) async => const Result.success(summary));
    when(() => repository.getChildResults(any())).thenAnswer((_) async => const Result.success([_result1]));

    await provider.selectChild('s2');

    expect(provider.selectedChildId, 's2');
    verify(() => repository.getChildResults('s2')).called(1);
  });
}
