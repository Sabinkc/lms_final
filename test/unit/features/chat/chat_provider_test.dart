import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/realtime/realtime_service.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/chat/data/models/eligible_target.dart';
import 'package:cloud_lms/features/chat/data/models/group_conversation.dart';
import 'package:cloud_lms/features/chat/data/models/group_message.dart';
import 'package:cloud_lms/features/chat/data/repositories/chat_repository.dart';
import 'package:cloud_lms/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockRealtimeService extends Mock implements RealtimeService {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

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
  lastMessagePreview: '',
  status: 'active',
);

const _message1 = GroupMessage(
  id: 'm1',
  conversationId: 'g1',
  senderRole: 'teacher',
  senderUserId: 'u1',
  senderName: 'Jane Teacher',
  text: 'Hello',
  attachment: null,
  readBy: ['u1'],
  createdAt: '2026-08-24T00:00:00.000Z',
);

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@test.dev',
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

void main() {
  late _MockChatRepository chatRepository;
  late _MockRealtimeService realtimeService;
  late _MockSecureStorageService secureStorage;
  late ChatProvider provider;

  setUp(() {
    chatRepository = _MockChatRepository();
    realtimeService = _MockRealtimeService();
    secureStorage = _MockSecureStorageService();
    // Every provider test here exercises the REST-driven paths only —
    // socket event delivery is explicitly "Integration (live)" tested per
    // implementation_backlog.md E10-F2, not unit-tested — so the socket is
    // kept disconnected throughout and every code path that touches
    // `.socket` short-circuits on this before ever reaching it.
    when(() => realtimeService.isConnected).thenReturn(false);
    when(() => realtimeService.connect(any())).thenAnswer((_) async {});
    when(() => realtimeService.disconnect()).thenReturn(null);
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'token');
    provider = ChatProvider(chatRepository, realtimeService, secureStorage);
  });

  test('loadGroups(): success populates groups and attempts a realtime connect', () async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([_group1]));

    await provider.loadGroups();

    expect(provider.groupsStatus, LoadStatus.success);
    expect(provider.groups, [_group1]);
    verify(() => realtimeService.connect('token')).called(1);
  });

  test('loadGroups(): failure sets error status', () async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadGroups();

    expect(provider.groupsStatus, LoadStatus.error);
  });

  test('loadEligibleTargets(): populates the create-group class/section picker', () async {
    const target = EligibleTarget(classId: 'c1', className: 'Class 10', hasSections: true, sections: []);
    when(() => chatRepository.getEligibleTargets()).thenAnswer((_) async => const Result.success([target]));

    await provider.loadEligibleTargets();

    expect(provider.eligibleTargets, [target]);
  });

  test('createGroup(): success prepends the new group', () async {
    when(() => chatRepository.createGroup(
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          name: any(named: 'name'),
          extraMemberIds: any(named: 'extraMemberIds'),
        )).thenAnswer((_) async => const Result.success(_group1));

    final succeeded = await provider.createGroup(classId: 'c1', sectionId: 'sec1');

    expect(succeeded, isTrue);
    expect(provider.groups, [_group1]);
  });

  test('createGroup(): failure (e.g. empty roster) surfaces the action error', () async {
    when(() => chatRepository.createGroup(
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          name: any(named: 'name'),
          extraMemberIds: any(named: 'extraMemberIds'),
        )).thenAnswer((_) async =>
        const Result.failure(ServerException('No students found for this class/section — the group would be empty.')));

    final succeeded = await provider.createGroup(classId: 'c1');

    expect(succeeded, isFalse);
    expect(provider.groups, isEmpty);
    expect(provider.actionError?.message, contains('would be empty'));
  });

  test('archiveGroup(): success removes it from the list', () async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([_group1]));
    await provider.loadGroups();
    when(() => chatRepository.archiveGroup(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.archiveGroup('g1');

    expect(succeeded, isTrue);
    expect(provider.groups, isEmpty);
  });

  test('deleteGroup(): success removes it from the list', () async {
    when(() => chatRepository.getMyGroups()).thenAnswer((_) async => const Result.success([_group1]));
    await provider.loadGroups();
    when(() => chatRepository.deleteGroup(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteGroup('g1');

    expect(succeeded, isTrue);
    expect(provider.groups, isEmpty);
  });

  test('updateMembers(): success reloads the member list', () async {
    when(() => chatRepository.updateMembers(any(),
        addStudentIds: any(named: 'addStudentIds'),
        removeStudentIds: any(named: 'removeStudentIds'))).thenAnswer((_) async => const Result.success(_group1));
    when(() => chatRepository.getGroupById(any())).thenAnswer((_) async => const Result.success((_group1, [_student1])));

    final succeeded = await provider.updateMembers('g1', addStudentIds: ['s1']);

    expect(succeeded, isTrue);
    expect(provider.groupMembers, [_student1]);
  });

  test('openThread(): loads message history for the given conversation', () async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_message1]));
    when(() => chatRepository.markRead(any())).thenAnswer((_) async => const Result.success(null));

    await provider.openThread('g1');

    expect(provider.currentConversationId, 'g1');
    expect(provider.messagesStatus, LoadStatus.success);
    expect(provider.messages, [_message1]);
    verify(() => chatRepository.markRead('g1')).called(1);
  });

  test('openThread(): failure sets an error status', () async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.openThread('g1');

    expect(provider.messagesStatus, LoadStatus.error);
    verifyNever(() => chatRepository.markRead(any()));
  });

  test('closeThread(): clears the current thread state', () async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_message1]));
    when(() => chatRepository.markRead(any())).thenAnswer((_) async => const Result.success(null));
    await provider.openThread('g1');

    provider.closeThread();

    expect(provider.currentConversationId, isNull);
    expect(provider.messages, isEmpty);
    expect(provider.messagesStatus, LoadStatus.initial);
  });

  test('sendMessage(): success appends the message to the open thread', () async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => chatRepository.markRead(any())).thenAnswer((_) async => const Result.success(null));
    await provider.openThread('g1');

    when(() => chatRepository.sendMessage(
          any(),
          text: any(named: 'text'),
          attachmentBytes: any(named: 'attachmentBytes'),
          attachmentFilename: any(named: 'attachmentFilename'),
        )).thenAnswer((_) async => const Result.success(_message1));

    final succeeded = await provider.sendMessage(text: 'Hello');

    expect(succeeded, isTrue);
    expect(provider.messages, [_message1]);
  });

  test('sendMessage(): with no open thread does nothing and returns false', () async {
    final succeeded = await provider.sendMessage(text: 'Hello');

    expect(succeeded, isFalse);
    verifyNever(() => chatRepository.sendMessage(
          any(),
          text: any(named: 'text'),
          attachmentBytes: any(named: 'attachmentBytes'),
          attachmentFilename: any(named: 'attachmentFilename'),
        ));
  });

  test('sendMessage(): failure surfaces the send error, message list untouched', () async {
    when(() => chatRepository.getMessages(any(), before: any(named: 'before'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => chatRepository.markRead(any())).thenAnswer((_) async => const Result.success(null));
    await provider.openThread('g1');

    when(() => chatRepository.sendMessage(
          any(),
          text: any(named: 'text'),
          attachmentBytes: any(named: 'attachmentBytes'),
          attachmentFilename: any(named: 'attachmentFilename'),
        )).thenAnswer((_) async => const Result.failure(ServerException('This group is archived')));

    final succeeded = await provider.sendMessage(text: 'Hello');

    expect(succeeded, isFalse);
    expect(provider.messages, isEmpty);
    expect(provider.sendError?.message, contains('archived'));
  });
}
