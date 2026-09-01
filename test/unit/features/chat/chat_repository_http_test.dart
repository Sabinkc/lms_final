import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/chat/data/repositories/chat_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ChatRepositoryHttp repository;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    final secureStorage = _MockSecureStorageService();
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token');

    final dio = Dio()..httpClientAdapter = fakeAdapter;
    final apiClient = ApiClient(
      env: const EnvConfig(environment: AppEnvironment.dev, baseUrl: 'http://test.local', verboseLogging: false),
      secureStorage: secureStorage,
      dio: dio,
    );

    repository = ChatRepositoryHttp(apiClient);
  });

  test('getEligibleTargets(): parses classes with nested sections', () async {
    fakeAdapter.when(
      '/group-chats/eligible-targets',
      (_) => jsonResponseBody({
        'success': true,
        'department': 'Science',
        'data': [
          {
            'classId': 'c1',
            'className': 'Class 10',
            'hasSections': true,
            'sections': [
              {'_id': 'sec1', 'name': 'A'},
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getEligibleTargets();

    result.when(
      success: (targets) {
        expect(targets.single.className, 'Class 10');
        expect(targets.single.sections.single.name, 'A');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('previewRoster(): parses students via the shared Student model', () async {
    fakeAdapter.when(
      '/group-chats/preview-roster',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 's1',
            'userId': {'fullName': 'Sam Student'},
            'class': 'Class 10',
            'section': 'A',
          },
        ],
      }, 200),
    );

    final result = await repository.previewRoster(classId: 'c1');

    result.when(
      success: (students) => expect(students.single.fullName, 'Sam Student'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createGroup(): posts classId/sectionId/name and parses the created group', () async {
    fakeAdapter.when(
      '/group-chats',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'g1',
          'name': 'Class 10 - A',
          'classId': 'c1',
          'className': 'Class 10',
          'sectionId': 'sec1',
          'sectionName': 'A',
          'teachers': ['t1'],
          'members': ['s1', 's2'],
          'status': 'active',
          'lastMessagePreview': '',
        },
      }, 201),
    );

    final result = await repository.createGroup(classId: 'c1', sectionId: 'sec1');

    result.when(
      success: (group) {
        expect(group.name, 'Class 10 - A');
        expect(group.memberIds, ['s1', 's2']);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyGroups(): parses bare (unpopulated) teacher/member id arrays', () async {
    fakeAdapter.when(
      '/group-chats',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'g1',
            'name': 'Class 10 - A',
            'classId': 'c1',
            'className': 'Class 10',
            'sectionId': 'sec1',
            'sectionName': 'A',
            'teachers': [
              {'_id': 't1', 'employeeId': 'EMP001'},
            ],
            'members': ['s1', 's2'],
            'status': 'active',
            'lastMessagePreview': 'Hello',
          },
        ],
      }, 200),
    );

    final result = await repository.getMyGroups();

    result.when(
      success: (groups) {
        expect(groups.single.teacherIds, ['t1']);
        expect(groups.single.memberIds, ['s1', 's2']);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getGroupById(): parses (group, members) as one tuple, members fully populated', () async {
    fakeAdapter.when(
      '/group-chats/g1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'g1',
          'name': 'Class 10 - A',
          'classId': 'c1',
          'className': 'Class 10',
          'sectionId': 'sec1',
          'sectionName': 'A',
          'teachers': [
            {'_id': 't1', 'employeeId': 'EMP001'},
          ],
          'members': [
            {
              '_id': 's1',
              'userId': {'fullName': 'Sam Student'},
              'class': 'Class 10',
              'section': 'A',
            },
          ],
          'status': 'active',
          'lastMessagePreview': '',
        },
      }, 200),
    );

    final result = await repository.getGroupById('g1');

    result.when(
      success: (data) {
        final (group, members) = data;
        expect(group.name, 'Class 10 - A');
        expect(members.single.fullName, 'Sam Student');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('updateMembers(): patches add/remove ids and parses the updated group', () async {
    fakeAdapter.when(
      '/group-chats/g1/members',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'g1',
          'name': 'Class 10 - A',
          'classId': 'c1',
          'className': 'Class 10',
          'sectionId': null,
          'sectionName': null,
          'teachers': ['t1'],
          'members': ['s1'],
          'status': 'active',
          'lastMessagePreview': '',
        },
      }, 200),
    );

    final result = await repository.updateMembers('g1', addStudentIds: ['s1']);

    result.when(
      success: (group) => expect(group.memberIds, ['s1']),
      failure: (_) => fail('expected success'),
    );
  });

  test('archiveGroup(): patches /:id/archive', () async {
    fakeAdapter.when('/group-chats/g1/archive', (_) => jsonResponseBody({'success': true, 'message': 'Group archived'}, 200));

    final result = await repository.archiveGroup('g1');

    expect(result.isSuccess, isTrue);
  });

  test('deleteGroup(): deletes /:id', () async {
    fakeAdapter.when('/group-chats/g1', (_) => jsonResponseBody({'success': true, 'message': 'Group deleted'}, 200));

    final result = await repository.deleteGroup('g1');

    expect(result.isSuccess, isTrue);
  });

  test('getMessages(): parses flattened senderUserId + senderName', () async {
    fakeAdapter.when(
      '/group-chats/g1/messages',
      (_) => jsonResponseBody({
        'success': true,
        'data': [
          {
            '_id': 'm1',
            'conversationId': 'g1',
            'senderRole': 'teacher',
            'senderUserId': 'u1',
            'senderName': 'Jane Teacher',
            'text': 'Hello class',
            'attachment': null,
            'readBy': ['u1'],
            'createdAt': '2026-08-24T00:00:00.000Z',
          },
        ],
      }, 200),
    );

    final result = await repository.getMessages('g1');

    result.when(
      success: (messages) => expect(messages.single.senderName, 'Jane Teacher'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getMessages(): parses an image attachment when present', () async {
    fakeAdapter.when(
      '/group-chats/g1/messages',
      (_) => jsonResponseBody({
        'success': true,
        'data': [
          {
            '_id': 'm1',
            'conversationId': 'g1',
            'senderRole': 'student',
            'senderUserId': 'u2',
            'senderName': 'Sam Student',
            'text': '',
            'attachment': {
              'type': 'image',
              'url': 'https://cloudinary.test/photo.jpg',
              'thumbnailUrl': null,
              'durationSeconds': null,
            },
            'readBy': [],
            'createdAt': '2026-08-24T00:00:00.000Z',
          },
        ],
      }, 200),
    );

    final result = await repository.getMessages('g1');

    result.when(
      success: (messages) {
        expect(messages.single.attachment?.type, 'image');
        expect(messages.single.attachment?.url, 'https://cloudinary.test/photo.jpg');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('sendMessage(): posts multipart form data even with no attachment', () async {
    fakeAdapter.when(
      '/group-chats/g1/messages',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'm2',
          'conversationId': 'g1',
          'senderRole': 'teacher',
          'senderUserId': 'u1',
          'senderName': 'Jane Teacher',
          'text': 'Hi',
          'attachment': null,
          'readBy': ['u1'],
          'createdAt': '2026-08-24T00:00:00.000Z',
        },
      }, 201),
    );

    final result = await repository.sendMessage('g1', text: 'Hi');

    result.when(
      success: (message) => expect(message.text, 'Hi'),
      failure: (_) => fail('expected success'),
    );
  });

  test('markRead(): patches /:conversationId/messages/read', () async {
    fakeAdapter.when(
      '/group-chats/g1/messages/read',
      (_) => jsonResponseBody({'success': true, 'message': 'Marked as read'}, 200),
    );

    final result = await repository.markRead('g1');

    expect(result.isSuccess, isTrue);
  });
}
