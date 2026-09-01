import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/department_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late DepartmentRepositoryHttp repository;

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

    repository = DepartmentRepositoryHttp(apiClient);
  });

  test('getDepartments(): parses a populated headOfDepartmentId into id + display name', () async {
    fakeAdapter.when(
      '/admin/departments',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'd1',
            'name': 'Science',
            'description': 'STEM subjects',
            'headOfDepartmentId': {
              '_id': 't1',
              'employeeId': 'EMP001',
              'userId': {'fullName': 'Jane Teacher'},
            },
            'classes': ['Class 9', 'Class 10'],
            'status': 'active',
          },
        ],
      }, 200),
    );

    final result = await repository.getDepartments();

    result.when(
      success: (departments) {
        expect(departments, hasLength(1));
        expect(departments[0].headOfDepartmentId, 't1');
        expect(departments[0].headOfDepartmentName, 'Jane Teacher');
        expect(departments[0].classes, ['Class 9', 'Class 10']);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getDepartments(): a department with no head parses headOfDepartmentId as null', () async {
    fakeAdapter.when(
      '/admin/departments',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {'_id': 'd1', 'name': 'Arts', 'description': '', 'headOfDepartmentId': null, 'classes': [], 'status': 'active'},
        ],
      }, 200),
    );

    final result = await repository.getDepartments();

    result.when(
      success: (departments) => expect(departments[0].headOfDepartmentId, isNull),
      failure: (_) => fail('expected success'),
    );
  });

  test('createDepartment(): posts fields and parses the created department (unpopulated head id)', () async {
    fakeAdapter.when(
      '/admin/departments',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'd1',
          'name': 'Science',
          'description': 'STEM subjects',
          'headOfDepartmentId': 't1',
          'classes': ['Class 9'],
          'status': 'active',
        },
      }, 201),
    );

    final result = await repository.createDepartment(name: 'Science', description: 'STEM subjects', headOfDepartmentId: 't1', classes: ['Class 9']);

    result.when(
      success: (created) {
        expect(created.name, 'Science');
        expect(created.headOfDepartmentId, 't1');
        expect(created.headOfDepartmentName, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createDepartment(): a duplicate name (409, confirmed conflict shape) surfaces the backend message', () async {
    fakeAdapter.when(
      '/admin/departments',
      (_) => jsonResponseBody({'success': false, 'message': 'A department with this name already exists'}, 409),
    );

    final result = await repository.createDepartment(name: 'Science');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'A department with this name already exists'),
    );
  });

  test('updateDepartment(): puts only the provided fields and parses the updated department', () async {
    fakeAdapter.when(
      '/admin/departments/d1',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Department updated',
        'data': {'_id': 'd1', 'name': 'Science & Math', 'description': '', 'headOfDepartmentId': null, 'classes': [], 'status': 'active'},
      }, 200),
    );

    final result = await repository.updateDepartment(id: 'd1', name: 'Science & Math');

    result.when(
      success: (updated) => expect(updated.name, 'Science & Math'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteDepartment(): success returns no data', () async {
    fakeAdapter.when('/admin/departments/d1', (_) => jsonResponseBody({'success': true, 'message': 'Department deleted'}, 200));

    final result = await repository.deleteDepartment('d1');

    expect(result.isSuccess, isTrue);
  });

  test('deleteDepartment(): not found (404) surfaces the backend message', () async {
    fakeAdapter.when('/admin/departments/d1', (_) => jsonResponseBody({'message': 'Department not found'}, 404));

    final result = await repository.deleteDepartment('d1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'Department not found'),
    );
  });
}
