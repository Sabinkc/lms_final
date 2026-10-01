import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/notices/data/models/notice.dart';
import 'package:cloud_lms/features/notices/data/repositories/notice_repository.dart';
import 'package:cloud_lms/features/notices/presentation/providers/notice_provider.dart';
import 'package:cloud_lms/features/notices/presentation/screens/notices_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockNoticeRepository extends Mock implements NoticeRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _notice1 = Notice(
  id: 'n1',
  title: 'School Holiday',
  description: 'School closed on Friday',
  audience: 'all',
  isImportant: true,
  expiryDate: null,
  createdByName: 'Admin Person',
  createdAt: '2026-08-24T00:00:00.000Z',
);

AuthSession _sessionWithRole(AppRole role) => AuthSession(
      user: AppUser(id: 'u1', fullName: 'Test User', email: 't@school.test', role: role),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

/// See assignments' `_authAs` doc comment (same helper, copied per-file to
/// avoid a test-only cross-feature import): never `await Future.delayed`
/// inside `testWidgets` — it hangs the whole test process under the fake
/// clock. Construct synchronously and let `pumpAndSettle()` drain it.
AuthProvider _authAs(_MockAuthRepository authRepository, AppRole role) {
  when(() => authRepository.restoreSession()).thenAnswer((_) async => _sessionWithRole(role));
  return AuthProvider(authRepository);
}

Widget _wrap(NoticeProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<NoticeProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(home: NoticesListScreen()),
    );

void main() {
  late _MockNoticeRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockNoticeRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getMyNotices()).thenAnswer((_) => Completer<Result<List<Notice>>>().future);
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Student role calls getMyNotices, not getNoticesAsAdmin, and sees no FAB', (tester) async {
    when(() => repository.getMyNotices()).thenAnswer((_) async => const Result.success([_notice1]));
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    verifyNever(() => repository.getNoticesAsAdmin(audience: any(named: 'audience')));
  });

  testWidgets('Admin role calls getNoticesAsAdmin and sees a FAB plus an edit/delete menu', (tester) async {
    when(() => repository.getNoticesAsAdmin(audience: any(named: 'audience')))
        .thenAnswer((_) async => const Result.success([_notice1]));
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    // Edit/Delete live in the card's ⋮ menu.
    await tester.tap(find.byTooltip('Notice actions'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('empty state shows a role-appropriate CTA for Admin', (tester) async {
    when(() => repository.getNoticesAsAdmin(audience: any(named: 'audience')))
        .thenAnswer((_) async => const Result.success([]));
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('No notices yet'), findsOneWidget);
    expect(find.text('Add Notice'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getMyNotices()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_notice1]);
    });
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
  });

  testWidgets('Admin add-notice flow: FAB -> form -> save calls createNotice and closes the dialog', (tester) async {
    when(() => repository.getNoticesAsAdmin(audience: any(named: 'audience')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => repository.createNotice(
          title: any(named: 'title'),
          description: any(named: 'description'),
          audience: any(named: 'audience'),
          isImportant: any(named: 'isImportant'),
          expiryDate: any(named: 'expiryDate'),
        )).thenAnswer((_) async => const Result.success(_notice1));
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.admin);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Notice'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'School Holiday');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'School closed on Friday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => repository.createNotice(
          title: 'School Holiday',
          description: 'School closed on Friday',
          audience: 'all',
          isImportant: false,
          expiryDate: any(named: 'expiryDate'),
        )).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('category chips come from real fields (important -> Urgent, audience) and filter the list', (tester) async {
    const studentsNotice = Notice(
      id: 'n2',
      title: 'Sports Day',
      description: 'Bring your kit',
      audience: 'students',
      isImportant: false,
      expiryDate: null,
      createdByName: '',
      createdAt: '2026-08-20T00:00:00.000Z',
    );
    when(() => repository.getMyNotices()).thenAnswer((_) async => const Result.success([_notice1, studentsNotice]));
    final provider = NoticeProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Urgent'), findsWidgets); // chip + card tag
    expect(find.text('Students'), findsWidgets);
    expect(find.text('Teachers'), findsNothing); // no teacher notices -> no chip

    await tester.tap(find.text('Urgent').first);
    await tester.pumpAndSettle();
    expect(find.text('School Holiday'), findsOneWidget);
    expect(find.text('Sports Day'), findsNothing);
  });
}
