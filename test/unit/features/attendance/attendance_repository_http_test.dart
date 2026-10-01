import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_status.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
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

  test('getMySections(): parses classId as a populated {_id, name} object, not a bare id', () async {
    fakeAdapter.when(
      '/sections/my/teacher',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'sec1',
            'name': 'A',
            'classId': {'_id': 'c1', 'name': 'Class 10'},
          },
        ],
      }, 200),
    );

    final result = await repository.getMySections();

    result.when(
      success: (sections) {
        expect(sections, hasLength(1));
        expect(sections[0].className, 'Class 10');
        expect(sections[0].classId, 'c1');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getSectionRoster(): parses students via the shared Student model', () async {
    fakeAdapter.when(
      '/sections/sec1/students',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 's1',
            'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
            'class': 'Class 10',
            'section': 'A',
          },
        ],
      }, 200),
    );

    final result = await repository.getSectionRoster('sec1');

    result.when(
      success: (roster) => expect(roster.single.fullName, 'Sam Student'),
      failure: (_) => fail('expected success'),
    );
  });

  test('markAttendance(): posts sectionId/date/records and parses saved/failed counts', () async {
    fakeAdapter.when(
      '/attendance/student',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Attendance saved: 1 recorded, 0 failed. This session is now locked.',
        'data': {
          'session': {'_id': 'sess1'},
          'saved': [
            {'_id': 'rec1'},
          ],
          'failed': [],
        },
      }, 201),
    );

    final result = await repository.markAttendance(
      sectionId: 'sec1',
      date: '2026-08-23',
      records: [const AttendanceRecordInput(studentId: 's1', status: AttendanceStatus.present)],
    );

    result.when(
      success: (summary) {
        expect(summary.savedCount, 1);
        expect(summary.failed, isEmpty);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('markAttendance(): a duplicate submission (409, confirmed real conflict shape) surfaces the backend message',
      () async {
    fakeAdapter.when(
      '/attendance/student',
      (_) => jsonResponseBody({'success': false, 'message': 'Attendance has already been submitted.'}, 409),
    );

    final result = await repository.markAttendance(
      sectionId: 'sec1',
      date: '2026-08-23',
      records: [const AttendanceRecordInput(studentId: 's1', status: AttendanceStatus.present)],
    );

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('already been submitted')),
    );
  });

  test('getSessions(): sends date as a query param and parses session summaries with counts', () async {
    fakeAdapter.when(
      '/attendance/student',
      (_) => jsonResponseBody({
        'success': true,
        'page': 1,
        'totalPages': 1,
        'total': 1,
        'data': [
          {
            '_id': 'sess1',
            'class': 'Class 10',
            'section': 'A',
            'subject': 'General',
            'date': '2026-08-23',
            'presentCount': 8,
            'absentCount': 1,
            'lateCount': 1,
            'totalCount': 10,
            'locked': true,
          },
        ],
      }, 200),
    );

    final result = await repository.getSessions(date: '2026-08-23');

    result.when(
      success: (sessions) {
        expect(sessions.single.presentCount, 8);
        expect(sessions.single.totalCount, 10);
        expect(sessions.single.locked, isTrue);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getSessions(): groups the per-student rows the live API returns into one summary per class', () async {
    fakeAdapter.when(
      '/attendance/student',
      (_) => jsonResponseBody({
        'success': true,
        'page': 1,
        'totalPages': 1,
        'total': 1,
        'data': [
          {'date': '2026-09-05', 'status': 'present', 'studentName': 'Sam Student', 'className': 'Class 10 A'},
          {'date': '2026-09-05', 'status': 'present', 'studentName': 'Tom Student', 'className': 'Class 10 A'},
          {'date': '2026-09-05', 'status': 'late', 'studentName': 'Amy Student', 'className': 'Class 10 A'},
          {'date': '2026-09-05', 'status': 'absent', 'studentName': 'Kim Student', 'className': 'Class 9 B'},
        ],
      }, 200),
    );

    final result = await repository.getSessions(date: '2026-09-05');

    result.when(
      success: (sessions) {
        expect(sessions, hasLength(2));
        expect(sessions[0].title, 'Class 10 A');
        expect((sessions[0].presentCount, sessions[0].lateCount, sessions[0].totalCount), (2, 1, 3));
        expect((sessions[1].absentCount, sessions[1].totalCount), (1, 1));
        expect(sessions[0].locked, isFalse);
      },
      failure: (_) => fail('expected success'),
    );
  });
}
