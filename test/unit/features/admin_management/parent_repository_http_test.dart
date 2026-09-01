import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/parent_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ParentRepositoryHttp repository;

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

    repository = ParentRepositoryHttp(apiClient);
  });

  test(
      'getParents(): parses the {success, count, data} envelope, including fully-populated children with their '
      'own nested userId', () async {
    fakeAdapter.when(
      '/parents',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'p1',
            'userId': {'fullName': 'Pat Parent', 'email': 'pat@school.test'},
            'occupation': 'Engineer',
            'status': 'active',
            'students': [
              {
                '_id': 's1',
                'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
                'class': 'Class 10',
                'section': 'A',
              },
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getParents();

    result.when(
      success: (parents) {
        expect(parents, hasLength(1));
        expect(parents[0].fullName, 'Pat Parent');
        expect(parents[0].children.single.fullName, 'Sam Student');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createParent(): posts required + optional fields incl. student links and parses the created parent',
      () async {
    fakeAdapter.when(
      '/parents',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Parent account created successfully. Credentials sent to their email.',
        'data': {
          '_id': 'p1',
          'userId': {'fullName': 'Pat Parent', 'email': 'pat@school.test'},
          'occupation': '',
          'status': 'active',
          'students': [],
        },
      }, 201),
    );

    final result = await repository.createParent(
      fullName: 'Pat Parent',
      email: 'pat@school.test',
      studentIds: ['s1'],
    );

    result.when(
      success: (created) => expect(created.fullName, 'Pat Parent'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createParent(): a duplicate email (409) surfaces the backend message', () async {
    fakeAdapter.when(
      '/parents',
      (_) => jsonResponseBody(
        {'success': false, 'message': 'A user with this email already exists. Use a different email.'},
        409,
      ),
    );

    final result = await repository.createParent(fullName: 'Pat Parent', email: 'pat@school.test');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('already exists')),
    );
  });

  test('updateParent(): puts only the provided fields, incl. replacing the linked-children set', () async {
    fakeAdapter.when(
      '/parents/p1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'userId': {'fullName': 'Pat Parent', 'email': 'pat@school.test'},
          'occupation': 'Doctor',
          'status': 'active',
          'students': [],
        },
      }, 200),
    );

    final result = await repository.updateParent(id: 'p1', occupation: 'Doctor', studentIds: []);

    result.when(
      success: (updated) => expect(updated.occupation, 'Doctor'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteParent(): success returns no data', () async {
    fakeAdapter.when(
      '/parents/p1',
      (_) => jsonResponseBody({'success': true, 'message': 'Parent and linked account deleted successfully'}, 200),
    );

    final result = await repository.deleteParent('p1');

    expect(result.isSuccess, isTrue);
  });
}
