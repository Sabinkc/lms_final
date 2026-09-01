import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late TeacherRepositoryHttp repository;

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

    repository = TeacherRepositoryHttp(apiClient);
  });

  test('getTeachers(): parses the {success, count, data} envelope, reaching into populated userId for name/email',
      () async {
    fakeAdapter.when(
      '/teachers',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 't1',
            'userId': {'fullName': 'Jane Teacher', 'email': 'jane@school.test'},
            'employeeId': 'EMP001',
            'department': 'Science',
            'status': 'active',
          },
        ],
      }, 200),
    );

    final result = await repository.getTeachers();

    result.when(
      success: (teachers) {
        expect(teachers, hasLength(1));
        expect(teachers[0].fullName, 'Jane Teacher');
        expect(teachers[0].email, 'jane@school.test');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createTeacher(): posts required + optional fields and parses the created teacher', () async {
    fakeAdapter.when(
      '/teachers',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Teacher account created successfully. Credentials sent to their email.',
        'data': {
          '_id': 't1',
          'userId': {'fullName': 'Jane Teacher', 'email': 'jane@school.test'},
          'employeeId': 'EMP001',
          'department': 'Science',
          'status': 'active',
        },
      }, 201),
    );

    final result = await repository.createTeacher(
      fullName: 'Jane Teacher',
      email: 'jane@school.test',
      employeeId: 'EMP001',
      department: 'Science',
    );

    result.when(
      success: (created) => expect(created.employeeId, 'EMP001'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createTeacher(): a duplicate email (409) surfaces the backend message', () async {
    fakeAdapter.when(
      '/teachers',
      (_) => jsonResponseBody(
        {'success': false, 'message': 'A user with this email already exists. Use a different email.'},
        409,
      ),
    );

    final result = await repository.createTeacher(
      fullName: 'Jane Teacher',
      email: 'jane@school.test',
      employeeId: 'EMP001',
      department: 'Science',
    );

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('already exists')),
    );
  });

  test('updateTeacher(): puts only the provided fields and parses the updated teacher', () async {
    fakeAdapter.when(
      '/teachers/t1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 't1',
          'userId': {'fullName': 'Jane Teacher', 'email': 'jane@school.test'},
          'employeeId': 'EMP001',
          'department': 'Mathematics',
          'status': 'active',
        },
      }, 200),
    );

    final result = await repository.updateTeacher(id: 't1', department: 'Mathematics');

    result.when(
      success: (updated) => expect(updated.department, 'Mathematics'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteTeacher(): success returns no data', () async {
    fakeAdapter.when(
      '/teachers/t1',
      (_) => jsonResponseBody({'success': true, 'message': 'Teacher and linked account deleted successfully'}, 200),
    );

    final result = await repository.deleteTeacher('t1');

    expect(result.isSuccess, isTrue);
  });
}
