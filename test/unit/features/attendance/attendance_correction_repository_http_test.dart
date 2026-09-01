import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_correction_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late AttendanceCorrectionRepositoryHttp repository;

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

    repository = AttendanceCorrectionRepositoryHttp(apiClient);
  });

  test('getCorrections(): parses the {success, page, total, data} envelope, leaving student/session ids raw',
      () async {
    fakeAdapter.when(
      '/attendance/corrections',
      (_) => jsonResponseBody({
        'success': true,
        'page': 1,
        'totalPages': 1,
        'total': 1,
        'data': [
          {
            '_id': 'corr1',
            'targetType': 'StudentAttendance',
            'attendanceSession': 'sess1',
            'student': 's1',
            'oldStatus': 'absent',
            'newStatus': 'present',
            'reason': 'Was actually present, marked by mistake',
            'status': 'pending',
            'requestedBy': 'u1',
          },
        ],
      }, 200),
    );

    final result = await repository.getCorrections(status: 'pending');

    result.when(
      success: (corrections) {
        expect(corrections, hasLength(1));
        expect(corrections[0].oldStatus, 'absent');
        expect(corrections[0].newStatus, 'present');
        expect(corrections[0].studentId, 's1');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('approve(): patches /:id/approve and parses the updated correction', () async {
    fakeAdapter.when(
      '/attendance/corrections/corr1/approve',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Correction approved and applied',
        'data': {
          '_id': 'corr1',
          'targetType': 'StudentAttendance',
          'oldStatus': 'absent',
          'newStatus': 'present',
          'reason': 'Was actually present',
          'status': 'approved',
          'requestedBy': 'u1',
        },
      }, 200),
    );

    final result = await repository.approve('corr1');

    result.when(
      success: (correction) => expect(correction.status, 'approved'),
      failure: (_) => fail('expected success'),
    );
  });

  test('reject(): patches /:id/reject and parses the updated correction', () async {
    fakeAdapter.when(
      '/attendance/corrections/corr1/reject',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Correction rejected',
        'data': {
          '_id': 'corr1',
          'targetType': 'StudentAttendance',
          'oldStatus': 'absent',
          'newStatus': 'present',
          'reason': 'Was actually present',
          'status': 'rejected',
          'requestedBy': 'u1',
        },
      }, 200),
    );

    final result = await repository.reject('corr1');

    result.when(
      success: (correction) => expect(correction.status, 'rejected'),
      failure: (_) => fail('expected success'),
    );
  });

  test('approve(): a request already reviewed (409, confirmed real conflict shape) surfaces the backend message',
      () async {
    fakeAdapter.when(
      '/attendance/corrections/corr1/approve',
      (_) => jsonResponseBody({'success': false, 'message': 'This request was already approved'}, 409),
    );

    final result = await repository.approve('corr1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('already approved')),
    );
  });
}
