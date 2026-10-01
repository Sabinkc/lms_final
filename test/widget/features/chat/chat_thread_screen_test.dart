import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/realtime/realtime_service.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_lms/features/chat/data/models/group_message.dart';
import 'package:cloud_lms/features/chat/data/repositories/chat_repository.dart';
import 'package:cloud_lms/features/chat/presentation/providers/chat_provider.dart';
import 'package:cloud_lms/features/chat/presentation/screens/chat_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockRealtimeService extends Mock implements RealtimeService {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

const _message1 = GroupMessage(
  id: 'm1',
  conversationId: 'g1',
  senderRole: 'student',
  senderUserId: 'u2',
  senderName: 'Sam Student',
  text: 'Hi teacher',
  attachment: null,
  readBy: ['u2'],
  createdAt: '2026-08-24T00:00:00.000Z',
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
      child: const MaterialApp(home: ChatThreadScreen(conversationId: 'g1')),
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
    when(() => chatRepository.markRead(any())).thenAnswer((_) async => const Result.success(null));
  });

  testWidgets('loading state shows a spinner', (tester) async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) => Completer<Result<List<GroupMessage>>>().future);
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('empty state shows a hello prompt', (tester) async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.student);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('No messages yet — say hello!'), findsOneWidget);
  });

  testWidgets('success state shows message text and marks the thread read', (tester) async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_message1]));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Hi teacher'), findsOneWidget);
    verify(() => chatRepository.markRead('g1')).called(1);
  });

  testWidgets('send flow: typing text and tapping send calls sendMessage and clears the field', (tester) async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => chatRepository.sendMessage(
          any(),
          text: any(named: 'text'),
          attachmentBytes: any(named: 'attachmentBytes'),
          attachmentFilename: any(named: 'attachmentFilename'),
        )).thenAnswer((_) async => const Result.success(_message1));
    final provider = ChatProvider(chatRepository, realtimeService, secureStorage);
    final authProvider = _authAs(authRepository, AppRole.teacher);

    await tester.pumpWidget(_wrap(provider, authProvider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello class');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    verify(() => chatRepository.sendMessage('g1', text: 'Hello class', attachmentBytes: null, attachmentFilename: null))
        .called(1);
    expect(find.widgetWithText(TextField, 'Hello class'), findsNothing);
  });
}
