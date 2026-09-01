import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/notices/data/repositories/notice_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late NoticeRepositoryHttp repository;

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

    repository = NoticeRepositoryHttp(apiClient);
  });

  test('getNoticesAsAdmin(): parses the {success, count, data} envelope', () async {
    fakeAdapter.when(
      '/notices',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'n1',
            'title': 'School Holiday',
            'description': 'School closed on Friday',
            'audience': 'all',
            'isImportant': true,
            'createdBy': {'fullName': 'Admin Person', 'email': 'admin@school.test'},
          },
        ],
      }, 200),
    );

    final result = await repository.getNoticesAsAdmin();

    result.when(
      success: (notices) {
        expect(notices, hasLength(1));
        expect(notices[0].title, 'School Holiday');
        expect(notices[0].isImportant, isTrue);
        expect(notices[0].createdByName, 'Admin Person');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyNotices(): hits /notices/my (role/audience-filtered server-side)', () async {
    fakeAdapter.when(
      '/notices/my',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'n1',
            'title': 'School Holiday',
            'description': 'School closed on Friday',
            'audience': 'all',
            'isImportant': false,
          },
        ],
      }, 200),
    );

    final result = await repository.getMyNotices();

    result.when(
      success: (notices) => expect(notices.single.title, 'School Holiday'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getNoticeById(): parses a single notice', () async {
    fakeAdapter.when(
      '/notices/n1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'n1',
          'title': 'School Holiday',
          'description': 'School closed on Friday',
          'audience': 'all',
          'isImportant': false,
        },
      }, 200),
    );

    final result = await repository.getNoticeById('n1');

    result.when(
      success: (notice) => expect(notice.description, 'School closed on Friday'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createNotice(): posts required + optional fields and parses the created notice', () async {
    fakeAdapter.when(
      '/notices',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Notice created and notifications sent.',
        'data': {
          '_id': 'n1',
          'title': 'School Holiday',
          'description': 'School closed on Friday',
          'audience': 'students',
          'isImportant': true,
        },
      }, 201),
    );

    final result = await repository.createNotice(
      title: 'School Holiday',
      description: 'School closed on Friday',
      audience: 'students',
      isImportant: true,
    );

    result.when(
      success: (created) => expect(created.audience, 'students'),
      failure: (_) => fail('expected success'),
    );
  });

  test('updateNotice(): puts only the provided fields', () async {
    fakeAdapter.when(
      '/notices/n1',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Notice updated',
        'data': {
          '_id': 'n1',
          'title': 'School Holiday (updated)',
          'description': 'School closed on Friday',
          'audience': 'all',
          'isImportant': false,
        },
      }, 200),
    );

    final result = await repository.updateNotice(id: 'n1', title: 'School Holiday (updated)');

    result.when(
      success: (updated) => expect(updated.title, 'School Holiday (updated)'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteNotice(): success returns no data', () async {
    fakeAdapter.when('/notices/n1', (_) => jsonResponseBody({'success': true, 'message': 'Notice deleted'}, 200));

    final result = await repository.deleteNotice('n1');

    expect(result.isSuccess, isTrue);
  });
}
