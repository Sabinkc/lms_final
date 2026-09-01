import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late NotificationRepositoryHttp repository;

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

    repository = NotificationRepositoryHttp(apiClient);
  });

  test('getNotifications(): parses (unreadCount, notifications) as one tuple', () async {
    fakeAdapter.when(
      '/notifications',
      (_) => jsonResponseBody({
        'success': true,
        'unreadCount': 1,
        'count': 2,
        'data': [
          {
            '_id': 'n1',
            'title': 'New Assignment',
            'message': 'Algebra Homework was posted',
            'type': 'assignment',
            'isRead': false,
            'refId': 'a1',
            'refModel': 'Assignment',
            'createdAt': '2026-08-25T00:00:00.000Z',
          },
          {
            '_id': 'n2',
            'title': 'Welcome',
            'message': 'Your account was created',
            'type': 'general',
            'isRead': true,
            'refId': null,
            'refModel': null,
            'createdAt': '2026-08-24T00:00:00.000Z',
          },
        ],
      }, 200),
    );

    final result = await repository.getNotifications();

    result.when(
      success: (data) {
        final (unreadCount, notifications) = data;
        expect(unreadCount, 1);
        expect(notifications, hasLength(2));
        expect(notifications.first.refModel, 'Assignment');
        expect(notifications.last.refModel, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('markRead(): patches /:id/read', () async {
    fakeAdapter.when(
      '/notifications/n1/read',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'n1',
          'title': 'New Assignment',
          'message': 'Algebra Homework was posted',
          'type': 'assignment',
          'isRead': true,
          'refId': 'a1',
          'refModel': 'Assignment',
          'createdAt': '2026-08-25T00:00:00.000Z',
        },
      }, 200),
    );

    final result = await repository.markRead('n1');

    expect(result.isSuccess, isTrue);
  });

  test('markAllRead(): patches /read-all', () async {
    fakeAdapter.when(
      '/notifications/read-all',
      (_) => jsonResponseBody({'success': true, 'message': 'All notifications marked as read', 'modifiedCount': 3}, 200),
    );

    final result = await repository.markAllRead();

    expect(result.isSuccess, isTrue);
  });
}
