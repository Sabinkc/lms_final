import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late SectionRepositoryHttp repository;

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

    repository = SectionRepositoryHttp(apiClient);
  });

  test('getSections(): hits the nested /classes/:classId/sections path and parses studentCount', () async {
    fakeAdapter.when(
      '/classes/c1/sections',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {'_id': 's1', 'name': 'A', 'classId': 'c1', 'status': 'active', 'studentCount': 24},
        ],
      }, 200),
    );

    final result = await repository.getSections('c1');

    result.when(
      success: (sections) {
        expect(sections, hasLength(1));
        expect(sections[0].studentCount, 24);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createSection(): posts under the class-scoped path and parses the created section '
      '(studentCount absent on create, defaults to 0)', () async {
    fakeAdapter.when(
      '/classes/c1/sections',
      (_) => jsonResponseBody({
        'success': true,
        'data': {'_id': 's1', 'name': 'A', 'classId': 'c1', 'status': 'active'},
      }, 201),
    );

    final result = await repository.createSection(classId: 'c1', name: 'A');

    result.when(
      success: (created) {
        expect(created.name, 'A');
        expect(created.studentCount, 0);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('updateSection(): puts to the flat /sections/:id path (a separate router from creation)', () async {
    fakeAdapter.when(
      '/sections/s1',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Section updated.',
        'data': {'_id': 's1', 'name': 'B', 'classId': 'c1', 'status': 'active'},
      }, 200),
    );

    final result = await repository.updateSection(id: 's1', name: 'B');

    result.when(
      success: (updated) => expect(updated.name, 'B'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteSection(): success (backend unassigns students but does not delete them)', () async {
    fakeAdapter.when(
      '/sections/s1',
      (_) => jsonResponseBody({'success': true, 'message': 'Section deleted. Students unassigned but not deleted.'}, 200),
    );

    final result = await repository.deleteSection('s1');

    expect(result.isSuccess, isTrue);
  });

  test('createSection(): duplicate name within the same class (409) surfaces the backend message', () async {
    fakeAdapter.when(
      '/classes/c1/sections',
      (_) => jsonResponseBody({
        'success': false,
        'message': 'A section with this name already exists in this class',
      }, 409),
    );

    final result = await repository.createSection(classId: 'c1', name: 'A');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'A section with this name already exists in this class'),
    );
  });
}
