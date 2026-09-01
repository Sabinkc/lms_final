import 'dart:typed_data';

import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late StudentRepositoryHttp repository;

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

    repository = StudentRepositoryHttp(apiClient);
  });

  test('getStudents(): parses the {success, count, data} envelope, reaching into populated userId for name/email',
      () async {
    fakeAdapter.when(
      '/students',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 's1',
            'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
            'class': 'Class 10',
            'section': 'A',
            'admissionNumber': 'ADM001',
            'status': 'active',
          },
        ],
      }, 200),
    );

    final result = await repository.getStudents();

    result.when(
      success: (students) {
        expect(students, hasLength(1));
        expect(students[0].fullName, 'Sam Student');
        expect(students[0].className, 'Class 10');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createStudent(): posts class/section as plain strings and parses the created student', () async {
    fakeAdapter.when(
      '/students',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 's1',
          'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
          'class': 'Class 10',
          'section': 'A',
          'status': 'active',
        },
      }, 201),
    );

    final result = await repository.createStudent(
      className: 'Class 10',
      section: 'A',
      fullName: 'Sam Student',
      email: 'sam@school.test',
    );

    result.when(
      success: (created) => expect(created.className, 'Class 10'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createStudent(): a duplicate admission number (409, confirmed real conflict shape) surfaces the backend '
      'message', () async {
    fakeAdapter.when(
      '/students',
      (_) => jsonResponseBody(
        {'success': false, 'message': 'Admission number "ADM001" is already used in this school.'},
        409,
      ),
    );

    final result = await repository.createStudent(className: 'Class 10', section: 'A', admissionNumber: 'ADM001');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('already used in this school')),
    );
  });

  test('updateStudent(): puts only the provided fields and parses the updated student', () async {
    fakeAdapter.when(
      '/students/s1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 's1',
          'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
          'class': 'Class 11',
          'section': 'A',
          'status': 'active',
        },
      }, 200),
    );

    final result = await repository.updateStudent(id: 's1', className: 'Class 11');

    result.when(
      success: (updated) => expect(updated.className, 'Class 11'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteStudent(): success returns no data', () async {
    fakeAdapter.when('/students/s1', (_) => jsonResponseBody({'success': true, 'message': 'deleted'}, 200));

    final result = await repository.deleteStudent('s1');

    expect(result.isSuccess, isTrue);
  });

  test('bulkImport(): parses the created/failed/totalRows summary', () async {
    fakeAdapter.when(
      '/students/bulk-import',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Import finished: 1 created, 1 failed.',
        'data': {
          'created': [
            {'row': 2, 'email': 'a@school.test', 'studentId': 's1'},
          ],
          'failed': [
            {'row': 3, 'email': 'b@school.test', 'reason': 'A user with this email already exists'},
          ],
          'totalRows': 2,
        },
      }, 201),
    );

    final result = await repository.bulkImport(Uint8List.fromList([1, 2, 3]), 'students.xlsx');

    result.when(
      success: (summary) {
        expect(summary.createdCount, 1);
        expect(summary.totalRows, 2);
        expect(summary.failed.single.reason, contains('already exists'));
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('downloadImportTemplate(): returns the raw bytes', () async {
    fakeAdapter.when('/students/bulk-import/template', (_) => bytesResponseBody([1, 2, 3, 4], 200));

    final result = await repository.downloadImportTemplate();

    result.when(
      success: (bytes) => expect(bytes, [1, 2, 3, 4]),
      failure: (_) => fail('expected success'),
    );
  });

  test('exportStudents(): returns the raw bytes', () async {
    fakeAdapter.when('/students/export', (_) => bytesResponseBody([5, 6, 7], 200));

    final result = await repository.exportStudents();

    result.when(
      success: (bytes) => expect(bytes, [5, 6, 7]),
      failure: (_) => fail('expected success'),
    );
  });
}
