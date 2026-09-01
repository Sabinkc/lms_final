import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_day.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late TimetableRepositoryHttp repository;

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

    repository = TimetableRepositoryHttp(apiClient);
  });

  test('getTimetables(): parses schedule with a populated teacherId', () async {
    fakeAdapter.when(
      '/timetable',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 't1',
            'className': 'Class 10',
            'section': 'A',
            'type': 'fixed',
            'weekNumber': null,
            'year': 2026,
            'schedule': [
              {
                'day': 'Monday',
                'periods': [
                  {
                    'periodNumber': 1,
                    'subject': 'Math',
                    'teacherId': {
                      '_id': 'tch1',
                      'employeeId': 'EMP001',
                      'userId': {'fullName': 'Jane Teacher'},
                    },
                    'startTime': '10:00 AM',
                    'endTime': '11:00 AM',
                    'room': '101',
                  },
                ],
              },
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getTimetables(className: 'Class 10', section: 'A');

    result.when(
      success: (timetables) {
        expect(timetables, hasLength(1));
        expect(timetables[0].schedule[0].day, 'Monday');
        final period = timetables[0].schedule[0].periods[0];
        expect(period.subject, 'Math');
        expect(period.teacherId, 'tch1');
        expect(period.teacherName, 'Jane Teacher');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('saveTimetable(): posts the schedule and parses the saved (unpopulated teacherId) document', () async {
    fakeAdapter.when(
      '/timetable',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Fixed timetable saved successfully',
        'data': {
          '_id': 't1',
          'className': 'Class 10',
          'section': 'A',
          'type': 'fixed',
          'weekNumber': null,
          'year': 2026,
          'schedule': [
            {
              'day': 'Monday',
              'periods': [
                {'periodNumber': 1, 'subject': 'Math', 'teacherId': 'tch1', 'startTime': '10:00 AM', 'endTime': '11:00 AM', 'room': '101'},
              ],
            },
          ],
        },
      }, 201),
    );

    final result = await repository.saveTimetable(
      className: 'Class 10',
      section: 'A',
      schedule: [
        const TimetableDayInput(
          day: 'Monday',
          periods: [
            TimetablePeriodInput(periodNumber: 1, subject: 'Math', teacherId: 'tch1', startTime: '10:00 AM', endTime: '11:00 AM', room: '101'),
          ],
        ),
      ],
    );

    result.when(
      success: (saved) {
        expect(saved.className, 'Class 10');
        expect(saved.schedule[0].periods[0].teacherId, 'tch1');
        expect(saved.schedule[0].periods[0].teacherName, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteTimetable(): success returns no data', () async {
    fakeAdapter.when('/timetable/t1', (_) => jsonResponseBody({'success': true, 'message': 'Timetable deleted'}, 200));

    final result = await repository.deleteTimetable('t1');

    expect(result.isSuccess, isTrue);
  });

  test('getMyTimetable(): a class with no timetable yet parses the empty shell, never a failure', () async {
    fakeAdapter.when(
      '/timetable/my',
      (_) => jsonResponseBody({
        'success': true,
        'empty': true,
        'type': 'fixed',
        'weekNumber': null,
        'today': 'Wednesday',
        'todaySchedule': {'day': 'Wednesday', 'periods': []},
        'fullSchedule': [],
      }, 200),
    );

    final result = await repository.getMyTimetable();

    result.when(
      success: (timetable) {
        expect(timetable.empty, isTrue);
        expect(timetable.today, 'Wednesday');
        expect(timetable.todaySchedule.periods, isEmpty);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyTimetable(): a real schedule parses today + full week with populated teacher names', () async {
    fakeAdapter.when(
      '/timetable/my',
      (_) => jsonResponseBody({
        'success': true,
        'empty': false,
        'type': 'fixed',
        'weekNumber': null,
        'today': 'Monday',
        'todaySchedule': {
          'day': 'Monday',
          'periods': [
            {
              'periodNumber': 1,
              'subject': 'Science',
              'teacherId': {'_id': 'tch2', 'employeeId': 'EMP002', 'userId': {'fullName': 'Sam Teacher'}},
              'startTime': '9:00 AM',
              'endTime': '10:00 AM',
              'room': null,
            },
          ],
        },
        'fullSchedule': [
          {'day': 'Monday', 'periods': []},
        ],
      }, 200),
    );

    final result = await repository.getMyTimetable();

    result.when(
      success: (timetable) {
        expect(timetable.empty, isFalse);
        expect(timetable.todaySchedule.periods[0].teacherName, 'Sam Teacher');
        expect(timetable.fullSchedule, hasLength(1));
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getTeacherTimetable(): parses flattened per-day entries with unpopulated teacherId', () async {
    fakeAdapter.when(
      '/timetable/teacher',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            'className': 'Class 10',
            'section': 'A',
            'type': 'fixed',
            'day': 'Monday',
            'periods': [
              {'periodNumber': 1, 'subject': 'Math', 'teacherId': 'tch1', 'startTime': '10:00 AM', 'endTime': '11:00 AM', 'room': '101'},
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getTeacherTimetable();

    result.when(
      success: (entries) {
        expect(entries, hasLength(1));
        expect(entries[0].className, 'Class 10');
        expect(entries[0].periods[0].teacherId, 'tch1');
        expect(entries[0].periods[0].teacherName, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });
}
