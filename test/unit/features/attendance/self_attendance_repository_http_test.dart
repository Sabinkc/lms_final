import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late AttendanceRepositoryHttp repository;

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

    repository = AttendanceRepositoryHttp(apiClient);
  });

  test('getMyStudentId(): resolves the caller\'s own actor profile id via /attendance/me', () async {
    fakeAdapter.when(
      '/attendance/me',
      (_) => jsonResponseBody({
        'success': true,
        'data': {'_id': 's1', 'class': 'Class 10', 'section': 'A'},
      }, 200),
    );

    final result = await repository.getMyStudentId();

    result.when(
      success: (id) => expect(id, 's1'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyChildren(): parses Parent.students[] via the shared Student model', () async {
    fakeAdapter.when(
      '/parents/me',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'userId': {'fullName': 'Pat Parent', 'email': 'pat@school.test'},
          'students': [
            {
              '_id': 's1',
              'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
              'class': 'Class 10',
              'section': 'A',
            },
          ],
        },
      }, 200),
    );

    final result = await repository.getMyChildren();

    result.when(
      success: (children) => expect(children.single.fullName, 'Sam Student'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getStudentAttendanceHistory(): parses student name, summary, and records', () async {
    fakeAdapter.when(
      '/attendance/student/s1',
      (_) => jsonResponseBody({
        'success': true,
        'student': {'id': 's1', 'name': 'Sam Student', 'class': 'Class 10', 'section': 'A'},
        'summary': {'present': 8, 'absent': 1, 'late': 1, 'leave': 0, 'halfDay': 0, 'total': 10, 'percentage': 90},
        'data': [
          {
            '_id': 'rec1',
            'status': 'present',
            'attendanceSession': {'date': '2026-08-23', 'subject': 'General', 'class': 'Class 10', 'section': 'A'},
          },
        ],
      }, 200),
    );

    final result = await repository.getStudentAttendanceHistory(studentId: 's1');

    result.when(
      success: (history) {
        expect(history.studentName, 'Sam Student');
        expect(history.summary.percentage, 90);
        expect(history.records.single.date, '2026-08-23');
        expect(history.records.single.status, 'present');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getStudentAttendanceHistory(): unauthorized access (403, confirmed real shape) surfaces the backend message',
      () async {
    fakeAdapter.when(
      '/attendance/student/s1',
      (_) => jsonResponseBody({'success': false, 'message': 'Access denied. You are not linked to this student.'}, 403),
    );

    final result = await repository.getStudentAttendanceHistory(studentId: 's1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('not linked to this student')),
    );
  });
}
