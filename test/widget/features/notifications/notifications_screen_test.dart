import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cloud_lms/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _n1 = AppNotification(
  id: 'n1',
  title: 'New Assignment',
  message: 'Algebra Homework was posted',
  type: 'assignment',
  isRead: false,
  refId: 'a1',
  refModel: 'Assignment',
  createdAt: '2026-08-25T00:00:00.000Z',
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

Widget _wrap(NotificationProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const NotificationsScreen()),
            GoRoute(path: '/assignments/:id', builder: (context, state) => const SizedBox()),
          ],
        ),
      ),
    );

void main() {
  late _MockNotificationRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockNotificationRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets('loading state shows the skeleton loading view', (tester) async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) => Completer<Result<(int, List<AppNotification>)>>().future);
    final provider = NotificationProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows a message', (tester) async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((0, [])));
    final provider = NotificationProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('success state shows the unread count in the title and no Mark all read when everything is read',
      (tester) async {
    const readOnly = AppNotification(
      id: 'n2',
      title: 'Old',
      message: 'Already seen',
      type: 'general',
      isRead: true,
      refId: null,
      refModel: null,
      createdAt: '2026-08-20T00:00:00.000Z',
    );
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((0, [readOnly])));
    final provider = NotificationProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('tapping an unread notification marks it read and deep-links to its assignment', (tester) async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((1, [_n1])));
    when(() => repository.markRead(any())).thenAnswer((_) async => const Result.success(null));
    final provider = NotificationProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Notifications (1)'), findsOneWidget);

    await tester.tap(find.text('New Assignment'));
    await tester.pumpAndSettle();

    verify(() => repository.markRead('n1')).called(1);
    expect(find.byType(NotificationsScreen), findsNothing);
  });

  testWidgets('Mark all read button calls markAllRead and clears the unread count', (tester) async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((1, [_n1])));
    when(() => repository.markAllRead()).thenAnswer((_) async => const Result.success(null));
    final provider = NotificationProvider(repository);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    verify(() => repository.markAllRead()).called(1);
    expect(find.text('Notifications'), findsOneWidget);
  });
}
