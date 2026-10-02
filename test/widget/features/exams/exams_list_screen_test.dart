import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_repository.dart';
import 'package:cloud_lms/features/exams/presentation/providers/exam_provider.dart';
import 'package:cloud_lms/features/exams/presentation/screens/exams_list_screen.dart';
import 'package:cloud_lms/shared/widgets/filter_chip_bar.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockExamRepository extends Mock implements ExamRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _exam1 = Exam(
  id: 'e1',
  title: 'Mid Term',
  className: 'Class 10',
  section: 'A',
  subjects: [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
  examDate: '2026-09-01',
  status: 'upcoming',
);

const _publishedExam = Exam(
  id: 'e2',
  title: 'Final Term',
  className: 'Class 10',
  section: 'A',
  subjects: [],
  examDate: '2026-10-01',
  status: 'published',
);

AuthSession _sessionWithRole(AppRole role) => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Test User', email: 't@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

/// See assignments' `_authAs` doc comment: never `await Future.delayed`
/// inside `testWidgets` — construct synchronously, let `pumpAndSettle()`
/// drain the async restore.
AuthProvider _authAs(_MockAuthRepository authRepository, AppRole role) {
  when(() => authRepository.restoreSession()).thenAnswer((_) async => _sessionWithRole(role));
  return AuthProvider(authRepository);
}

Widget _wrap(ExamProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ExamProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(home: ExamsListScreen()),
    );

void main() {
  late _MockExamRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockExamRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getMyExams()).thenAnswer((_) => Completer<Result<List<Exam>>>().future);
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('Student role calls getMyExams and sees no FAB', (tester) async {
    when(() => repository.getMyExams()).thenAnswer((_) async => const Result.success([_exam1]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Mid Term'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    verifyNever(() => repository.getExamsAsAdmin());
  });

  testWidgets('card shows the class/section, a readable date and the total marks', (tester) async {
    when(() => repository.getMyExams()).thenAnswer((_) async => const Result.success([_exam1]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10 · Section A'), findsOneWidget);
    expect(find.text('1 Sep 2026'), findsWidgets);
    expect(find.text('100 Total Marks'), findsOneWidget);
  });

  testWidgets('card lists its subjects inline', (tester) async {
    when(() => repository.getMyExams()).thenAnswer((_) async => const Result.success([_exam1]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('100 marks'), findsOneWidget);
  });

  testWidgets('Admin sees a FAB and, once expanded, a Publish Results button for an unpublished exam',
      (tester) async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([_exam1]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.text('Mid Term'));
    await tester.pumpAndSettle();

    expect(find.text('Publish Results'), findsOneWidget);
    expect(find.text('View Results'), findsNothing);
  });

  testWidgets('Admin sees View Results instead of Publish Results for an already-published exam', (tester) async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([_publishedExam]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Final Term'));
    await tester.pumpAndSettle();

    expect(find.text('View Results'), findsOneWidget);
    expect(find.text('Publish Results'), findsNothing);
  });

  testWidgets('status chips and search narrow the list', (tester) async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([_exam1, _publishedExam]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Mid Term'), findsOneWidget);
    expect(find.text('Final Term'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppFilterChip, 'Published'));
    await tester.pumpAndSettle();
    expect(find.text('Mid Term'), findsNothing);
    expect(find.text('Final Term'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppFilterChip, 'All'));
    await tester.enterText(find.byType(TextField), 'math');
    await tester.pumpAndSettle();
    expect(find.text('Mid Term'), findsOneWidget);
    expect(find.text('Final Term'), findsNothing);
  });

  testWidgets('empty state shows the CTA for Admin', (tester) async {
    when(() => repository.getExamsAsAdmin()).thenAnswer((_) async => const Result.success([]));
    final provider = ExamProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('No exams scheduled yet'), findsOneWidget);
    expect(find.text('Add Exam'), findsWidgets);
  });
}
