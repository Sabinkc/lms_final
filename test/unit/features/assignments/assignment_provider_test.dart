import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/assignments/data/models/assignment.dart';
import 'package:cloud_lms/features/assignments/data/models/assignment_submission.dart';
import 'package:cloud_lms/features/assignments/data/repositories/assignment_repository.dart';
import 'package:cloud_lms/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAssignmentRepository extends Mock implements AssignmentRepository {}

const _assignment1 = Assignment(
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

const _submission1 = AssignmentSubmission(
  id: 'sub1',
  assignmentId: 'a1',
  submissionText: 'My work',
  attachments: [],
  submittedAt: '2026-08-25T00:00:00.000Z',
  marks: null,
  remarks: '',
  graded: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(<SubmissionFile>[]);
  });

  late _MockAssignmentRepository repository;
  late AssignmentProvider provider;

  setUp(() {
    repository = _MockAssignmentRepository();
    provider = AssignmentProvider(repository);
  });

  test('loadAssignments(): success populates assignments and sets status', () async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.success([_assignment1]));

    await provider.loadAssignments();

    expect(provider.status, LoadStatus.success);
    expect(provider.assignments, [_assignment1]);
  });

  test('loadAssignmentDetail(): success populates currentAssignment', () async {
    when(() => repository.getAssignmentById(any())).thenAnswer((_) async => const Result.success(_assignment1));

    await provider.loadAssignmentDetail('a1');

    expect(provider.detailStatus, LoadStatus.success);
    expect(provider.currentAssignment, _assignment1);
  });

  test('createAssignment(): success appends to the assignments list and returns true', () async {
    when(() => repository.createAssignment(
          title: any(named: 'title'),
          description: any(named: 'description'),
          className: any(named: 'className'),
          section: any(named: 'section'),
          subject: any(named: 'subject'),
          dueDate: any(named: 'dueDate'),
        )).thenAnswer((_) async => const Result.success(_assignment1));

    final succeeded = await provider.createAssignment(
      title: 'Algebra Homework',
      description: 'Chapter 4 exercises',
      className: 'Class 10',
      section: 'A',
      subject: 'Math',
      dueDate: '2026-09-01',
    );

    expect(succeeded, isTrue);
    expect(provider.assignments, [_assignment1]);
  });

  test('deleteAssignment(): success removes it from the list and clears a matching currentAssignment', () async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.success([_assignment1]));
    await provider.loadAssignments();
    when(() => repository.getAssignmentById(any())).thenAnswer((_) async => const Result.success(_assignment1));
    await provider.loadAssignmentDetail('a1');
    when(() => repository.deleteAssignment(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteAssignment('a1');

    expect(succeeded, isTrue);
    expect(provider.assignments, isEmpty);
    expect(provider.currentAssignment, isNull);
  });

  test('submitAssignment(): success returns true and clears any prior submit error', () async {
    when(() => repository.submitAssignment(
          assignmentId: any(named: 'assignmentId'),
          submissionText: any(named: 'submissionText'),
          files: any(named: 'files'),
        )).thenAnswer((_) async => const Result.success(_submission1));

    final succeeded = await provider.submitAssignment(assignmentId: 'a1', submissionText: 'My work');

    expect(succeeded, isTrue);
    expect(provider.submitError, isNull);
  });

  test('submitAssignment(): failure (e.g. past due date) surfaces the error', () async {
    when(() => repository.submitAssignment(
          assignmentId: any(named: 'assignmentId'),
          submissionText: any(named: 'submissionText'),
          files: any(named: 'files'),
        )).thenAnswer((_) async => const Result.failure(ServerException('Assignment due date has passed')));

    final succeeded = await provider.submitAssignment(assignmentId: 'a1');

    expect(succeeded, isFalse);
    expect(provider.submitError?.message, contains('due date has passed'));
  });

  test('gradeSubmission(): success updates the matching submission in place', () async {
    when(() => repository.getSubmissionsForAssignment(any()))
        .thenAnswer((_) async => const Result.success([_submission1]));
    await provider.loadSubmissionsForAssignment('a1');

    const graded = AssignmentSubmission(
      id: 'sub1',
      assignmentId: 'a1',
      submissionText: 'My work',
      attachments: [],
      submittedAt: '2026-08-25T00:00:00.000Z',
      marks: 85,
      remarks: 'Good work',
      graded: true,
    );
    when(() => repository.gradeSubmission(
          submissionId: any(named: 'submissionId'),
          marks: any(named: 'marks'),
          remarks: any(named: 'remarks'),
        )).thenAnswer((_) async => const Result.success(graded));

    final succeeded = await provider.gradeSubmission(submissionId: 'sub1', marks: 85, remarks: 'Good work');

    expect(succeeded, isTrue);
    expect(provider.submissions.single.graded, isTrue);
    expect(provider.submissions.single.marks, 85);
  });
}
