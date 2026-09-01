import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ClassRepositoryHttp repository;

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

    repository = ClassRepositoryHttp(apiClient);
  });

  test('getClasses(): parses the {success, count, data} envelope confirmed for GET /api/classes', () async {
    fakeAdapter.when(
      '/classes',
      (_) => jsonResponseBody({
        'success': true,
        'count': 2,
        'data': [
          {'_id': 'c1', 'name': 'Class 10', 'description': 'Grade 10', 'status': 'active'},
          {'_id': 'c2', 'name': 'Class 9', 'description': '', 'status': 'active'},
        ],
      }, 200),
    );

    final result = await repository.getClasses();

    result.when(
      success: (classes) {
        expect(classes, hasLength(2));
        expect(classes[0].id, 'c1');
        expect(classes[0].name, 'Class 10');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createClass(): posts name/description and parses the created class', () async {
    fakeAdapter.when(
      '/classes',
      (_) => jsonResponseBody({
        'success': true,
        'data': {'_id': 'c1', 'name': 'Class 10', 'description': 'Grade 10', 'status': 'active'},
      }, 201),
    );

    final result = await repository.createClass(name: 'Class 10', description: 'Grade 10');

    result.when(
      success: (created) => expect(created.name, 'Class 10'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createClass(): a duplicate name (409, confirmed real conflict shape) surfaces the backend message', () async {
    fakeAdapter.when(
      '/classes',
      (_) => jsonResponseBody({'success': false, 'message': 'A class with this name already exists'}, 409),
    );

    final result = await repository.createClass(name: 'Class 10');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'A class with this name already exists'),
    );
  });

  test('updateClass(): puts only the provided fields and parses the updated class', () async {
    fakeAdapter.when(
      '/classes/c1',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Class updated',
        'data': {'_id': 'c1', 'name': 'Class 10A', 'description': 'Grade 10', 'status': 'active'},
      }, 200),
    );

    final result = await repository.updateClass(id: 'c1', name: 'Class 10A');

    result.when(
      success: (updated) => expect(updated.name, 'Class 10A'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteClass(): a class with sections still under it (409, confirmed server guard) fails with the '
      "backend's message rather than deleting", () async {
    fakeAdapter.when(
      '/classes/c1',
      (_) => jsonResponseBody({
        'success': false,
        'message': 'Delete or reassign all sections under this class before deleting it',
      }, 409),
    );

    final result = await repository.deleteClass('c1');

    expect(result.isFailure, isTrue);
    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('sections under this class')),
    );
  });

  test('deleteClass(): success returns no data', () async {
    fakeAdapter.when('/classes/c1', (_) => jsonResponseBody({'success': true, 'message': 'deleted'}, 200));

    final result = await repository.deleteClass('c1');

    expect(result.isSuccess, isTrue);
  });
}
