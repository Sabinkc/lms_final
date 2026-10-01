import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/assignments/data/models/assignment.dart';
import 'package:cloud_lms/features/assignments/data/models/assignment_submission.dart';
import 'package:cloud_lms/features/assignments/data/repositories/assignment_repository.dart';
import 'package:cloud_lms/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:cloud_lms/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/shared/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAssignmentRepository extends Mock implements AssignmentRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

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

const _ungradedSubmission = AssignmentSubmission(
  id: 'sub1',
  assignmentId: 'a1',
  submissionText: 'My work',
  attachments: [],
  submittedAt: '2026-08-25T00:00:00.000Z',
  marks: null,
  remarks: '',
  graded: false,
  studentName: 'Sam Student',
  studentAdmissionNumber: 'ADM001',
);

AuthSession _sessionWithRole(AppRole role) => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Test User', email: 't@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

/// See `assignments_list_screen_test.dart`'s `_authAs` doc comment — do not
/// await a real `Future.delayed` inside `testWidgets`, it hangs forever
/// under the fake-clocked test binding. Construct synchronously and let
/// `pumpAndSettle()` drain the async restore.
AuthProvider _authAs(_MockAuthRepository authRepository, AppRole role) {
  when(() => authRepository.restoreSession()).thenAnswer((_) async => _sessionWithRole(role));
  return AuthProvider(authRepository);
}

Widget _wrap(AssignmentProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AssignmentProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(home: AssignmentDetailScreen(assignmentId: 'a1')),
    );

void main() {
  late _MockAssignmentRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockAssignmentRepository();
    authRepository = _MockAuthRepository();
    when(() => repository.getAssignmentById(any())).thenAnswer((_) async => const Result.success(_assignment1));
  });

  testWidgets('Teacher sees the submissions list and can grade an ungraded one', (tester) async {
    when(() => repository.getSubmissionsForAssignment(any()))
        .thenAnswer((_) async => const Result.success([_ungradedSubmission]));
    const graded = AssignmentSubmission(
      id: 'sub1',
      assignmentId: 'a1',
      submissionText: 'My work',
      attachments: [],
      submittedAt: '2026-08-25T00:00:00.000Z',
      marks: 90,
      remarks: 'Great job',
      graded: true,
      studentName: 'Sam Student',
    );
    when(() => repository.gradeSubmission(
          submissionId: any(named: 'submissionId'),
          marks: any(named: 'marks'),
          remarks: any(named: 'remarks'),
        )).thenAnswer((_) async => const Result.success(graded));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Algebra Homework'), findsOneWidget);
    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Grade'), findsOneWidget);

    await tester.ensureVisible(find.text('Grade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grade'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Marks'), '90');
    await tester.enterText(find.widgetWithText(TextFormField, 'Remarks (optional)'), 'Great job');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => repository.gradeSubmission(submissionId: 'sub1', marks: 90, remarks: 'Great job')).called(1);
    // "Graded" moved into an AppStatusChip on the submission card; the
    // marks/remarks line is now labeled "Marks:" instead of "Graded:".
    expect(find.textContaining('Marks: 90'), findsOneWidget);
    expect(find.widgetWithText(AppStatusPill, 'Graded'), findsOneWidget);
  });

  testWidgets('Student with no submission yet sees the submit form; submitting calls submitAssignment',
      (tester) async {
    when(() => repository.getMySubmissions()).thenAnswer((_) async => const Result.success([]));
    when(() => repository.submitAssignment(
          assignmentId: any(named: 'assignmentId'),
          submissionText: any(named: 'submissionText'),
          files: any(named: 'files'),
        )).thenAnswer((_) async => const Result.success(_ungradedSubmission));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Submit your work'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Submission text (optional)'), 'My answer');
    await tester.ensureVisible(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    verify(() => repository.submitAssignment(assignmentId: 'a1', submissionText: 'My answer', files: []))
        .called(1);
  });

  testWidgets('Student whose submissions fetch fails sees an error and a retry, not a stuck spinner',
      (tester) async {
    when(() => repository.getMySubmissions())
        .thenAnswer((_) async => const Result.failure(ForbiddenException('Only teachers can view submissions')));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Only teachers can view submissions'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    when(() => repository.getMySubmissions()).thenAnswer((_) async => const Result.success([]));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Submit your work'), findsOneWidget);
  });

  testWidgets('Student with an already-graded submission sees the grade, not a submit form', (tester) async {
    const graded = AssignmentSubmission(
      id: 'sub1',
      assignmentId: 'a1',
      submissionText: 'My work',
      attachments: [],
      submittedAt: '2026-08-25T00:00:00.000Z',
      marks: 90,
      remarks: 'Great job',
      graded: true,
    );
    when(() => repository.getMySubmissions()).thenAnswer((_) async => const Result.success([graded]));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Your submission has been graded'), findsOneWidget);
    expect(find.text('Marks: 90'), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });

  testWidgets('Parent role sees the read-only assignment info with no submission section', (tester) async {
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.parent);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Algebra Homework'), findsOneWidget);
    expect(find.text('Chapter 4 exercises'), findsOneWidget);
    expect(find.text('Due 1 Sep 2026'), findsOneWidget);
    expect(find.text('Submit your work'), findsNothing);
    expect(find.text('Submissions (0)'), findsNothing);
  });
}
