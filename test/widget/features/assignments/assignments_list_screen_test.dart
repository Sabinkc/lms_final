import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/assignments/data/models/assignment.dart';
import 'package:cloud_lms/features/assignments/data/repositories/assignment_repository.dart';
import 'package:cloud_lms/features/assignments/presentation/providers/assignment_provider.dart';
import 'package:cloud_lms/features/assignments/presentation/screens/assignments_list_screen.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
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

AuthSession _sessionWithRole(AppRole role) => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Test User', email: 't@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

/// [AuthProvider]'s constructor kicks off an async `restoreSession()` call
/// with no way to await it directly — **do not** try to flush it with a
/// real `Future.delayed` here: inside `testWidgets`, `AutomatedTestWidgets
/// FlutterBinding` fake-clocks time, so a real timer never fires and the
/// await hangs the whole test process forever (confirmed the hard way).
/// Matches `app_router_test.dart`'s `_appWith` pattern instead — construct
/// synchronously and let the caller's `tester.pump()`/`pumpAndSettle()`
/// (called after `pumpWidget`) drain it, the same way the widget tree
/// itself will already be pumping for its own async provider calls.
AuthProvider _authAs(_MockAuthRepository authRepository, AppRole role) {
  when(() => authRepository.restoreSession()).thenAnswer((_) async => _sessionWithRole(role));
  return AuthProvider(authRepository);
}

Widget _wrap(AssignmentProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AssignmentProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(home: AssignmentsListScreen()),
    );

void main() {
  late _MockAssignmentRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockAssignmentRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getAssignments()).thenAnswer((_) => Completer<Result<List<Assignment>>>().future);
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('Student role sees no FAB to add an assignment', (tester) async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.success([]));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('No assignments yet'), findsOneWidget);
  });

  testWidgets('Teacher role sees a FAB to add an assignment', (tester) async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.success([]));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('success state lists assignments with subject/class/due date', (tester) async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.success([_assignment1]));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Algebra Homework'), findsOneWidget);
    expect(find.text('Math · Class 10 A · Due 1 Sep 2026'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getAssignments()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_assignment1]);
    });
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Algebra Homework'), findsOneWidget);
  });

  testWidgets('Admin gets an explanation instead of a Retry when the server returns 403', (tester) async {
    when(() => repository.getAssignments()).thenAnswer((_) async => const Result.failure(ForbiddenException()));
    final provider = AssignmentProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.textContaining('does not yet let Admin accounts view them'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
