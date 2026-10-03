import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/realtime/realtime_service.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/chat/data/models/eligible_target.dart';
import 'package:cloud_lms/features/chat/data/models/group_conversation.dart';
import 'package:cloud_lms/features/chat/data/repositories/chat_repository.dart';
import 'package:cloud_lms/features/chat/presentation/providers/chat_provider.dart';
import 'package:cloud_lms/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockRealtimeService extends Mock implements RealtimeService {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _group1 = GroupConversation(
  id: 'g1',
  name: 'Class 10 - A',
  classId: 'c1',
  className: 'Class 10',
  sectionId: 'sec1',
  sectionName: 'A',
  teacherIds: ['t1'],
  memberIds: ['s1'],
  lastMessageAt: null,
  lastMessagePreview: 'Hello class',
  status: 'active',
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

Widget _wrap(ChatProvider provider, AuthProvider authProvider) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>.value(value: provider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const ChatListScreen()),
            GoRoute(path: '/chat/:id', builder: (context, state) => const SizedBox()),
          ],
        ),
      ),
    );

void main() {
  late _MockChatRepository chatRepository;
  late _MockRealtimeService realtimeService;
  late _MockSecureStorageService secureStorage;
  late _MockAuthRepository authRepository;

  setUp(() {
    chatRepository = _MockChatRepository();
    realtimeService = _MockRealtimeService();
    secureStorage = _MockSecureStorageService();
    authRepository = _MockAuthRepository();
    when(() => realtimeService.isConnected).thenReturn(false);
    when(() => realtimeService.connect(any())).thenAnswer((_) async {});
    when(() => realtimeService.disconnect()).thenReturn(null);
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'token');
  });

  testWidgets('loading state shows the skeleton loading view', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) => Completer<Result<List<GroupConversation>>>().future);
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('Student sees no New Group button', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newGroupAppBarButton')), findsNothing);
    expect(find.text('No group conversations yet'), findsOneWidget);
  });

  testWidgets('Teacher sees a New Group button to create a group', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newGroupAppBarButton')), findsOneWidget);
  });

  testWidgets('success state lists groups with their last message preview', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([_group1]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10 - A'), findsOneWidget);
    expect(find.text('Hello class'), findsOneWidget);
  });

  testWidgets('create-group flow: New Group button -> pick class -> create -> calls createGroup', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([]));
    when(() => chatRepository.getEligibleTargets()).thenAnswer((_) async => const Result.success([
          EligibleTarget(classId: 'c1', className: 'Class 10', hasSections: true, sections: [EligibleSection(id: 'sec1', name: 'A')]),
        ]));
    when(() => chatRepository.previewRoster(classId: any(named: 'classId'), sectionId: any(named: 'sectionId')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => chatRepository.createGroup(
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          name: any(named: 'name'),
          extraMemberIds: any(named: 'extraMemberIds'),
        )).thenAnswer((_) async => const Result.success(_group1));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('newGroupAppBarButton')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'New Group'), findsOneWidget);

    await tester.tap(find.widgetWithText(DropdownButtonFormField<EligibleTarget>, 'Class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 10').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    verify(() => chatRepository.createGroup(classId: 'c1', sectionId: null, name: null, extraMemberIds: any(named: 'extraMemberIds')))
        .called(1);
    expect(find.byType(FormSheet), findsNothing);
  });

  testWidgets('tapping a group navigates to its thread', (tester) async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([_group1]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Class 10 - A'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatListScreen), findsNothing);
  });
}
