import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/exams/data/models/exam_result.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_result_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_result_provider.dart';
import 'package:cloud_lms/features/exams/presentation/screens/exam_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockExamResultRepository extends Mock implements ExamResultRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

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

AuthSession _sessionWithRole(AppRole role) => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Test User', email: 't@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

AuthProvider _authAs(_MockAuthRepository authRepository, AppRole role) {
  when(() => authRepository.restoreSession()).thenAnswer((_) async => _sessionWithRole(role));
  return AuthProvider(authRepository);
}

Widget _wrap(ExamResultProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ExamResultProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(home: ExamResultsScreen(examId: 'e1')),
    );

void main() {
  late _MockExamResultRepository repository;
  late _MockStudentRepository studentRepository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockExamResultRepository();
    studentRepository = _MockStudentRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets('Admin sees the class summary and ranked results list', (tester) async {
    const summary = ClassResultsSummary(total: 1, passed: 1, failed: 0, avgPercentage: 85, gradeDistribution: {'A': 1});
    when(() => repository.getExamResults(any())).thenAnswer((_) async => const Result.success((summary, [_result1])));
    final provider = ExamResultProvider(repository, studentRepository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 passed, 0 failed'), findsOneWidget);
    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('A · 85.0%'), findsOneWidget);
  });

  testWidgets('Student sees their own result card', (tester) async {
    when(() => repository.getMyResultForExam(any())).thenAnswer((_) async => const Result.success(_result1));
    final provider = ExamResultProvider(repository, studentRepository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('Rank: 1'), findsOneWidget);
  });

  testWidgets('Parent with one child auto-selects and sees that child\'s result for this exam', (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1]));
    const summary = ResultsSummary(totalExams: 1, passed: 1, failed: 0, averagePercentage: 85);
    when(() => repository.getChildResultsSummary(any())).thenAnswer((_) async => const Result.success(summary));
    when(() => repository.getChildResults(any())).thenAnswer((_) async => const Result.success([_result1]));
    final provider = ExamResultProvider(repository, studentRepository);
    final authProvider = _authAs(authRepository, AppRole.parent);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Rank: 1'), findsOneWidget);
  });

  testWidgets('Parent with multiple children sees a prompt until picking one, then that child\'s result',
      (tester) async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));
    const summary = ResultsSummary(totalExams: 1, passed: 1, failed: 0, averagePercentage: 85);
    when(() => repository.getChildResultsSummary(any())).thenAnswer((_) async => const Result.success(summary));
    when(() => repository.getChildResults(any())).thenAnswer((_) async => const Result.success([_result1]));
    final provider = ExamResultProvider(repository, studentRepository);
    final authProvider = _authAs(authRepository, AppRole.parent);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('Select a child above to view their result'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sam Student'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
  });
}
