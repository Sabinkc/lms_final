import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/student_followups/data/repositories/student_followup_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late StudentFollowupRepositoryHttp repository;

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

    repository = StudentFollowupRepositoryHttp(apiClient);
  });

  test('getFollowups(): parses a populated createdBy into a display name', () async {
    fakeAdapter.when(
      '/admin/student-followups',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'total': 1,
        'page': 1,
        'pages': 1,
        'data': [
          {
            '_id': 'f1',
            'studentName': 'Sam Prospect',
            'faculty': 'Science',
            'email': 'sam@test.dev',
            'contactNumber': '9800000000',
            'address': 'Kathmandu',
            'followUpNote': 'Interested in Class 10 admission',
            'visitDate': '2026-08-20T00:00:00.000Z',
            'status': 'pending',
            'createdBy': {'_id': 'a1', 'fullName': 'Alice Admin', 'email': 'alice@test.dev'},
          },
        ],
      }, 200),
    );

    final result = await repository.getFollowups();

    result.when(
      success: (followups) {
        expect(followups, hasLength(1));
        expect(followups[0].studentName, 'Sam Prospect');
        expect(followups[0].createdByName, 'Alice Admin');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createFollowup(): posts required fields and parses the created record (unpopulated createdBy)', () async {
    fakeAdapter.when(
      '/admin/student-followups',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'f1',
          'studentName': 'Sam Prospect',
          'faculty': 'Science',
          'email': 'sam@test.dev',
          'contactNumber': '9800000000',
          'address': 'Kathmandu',
          'followUpNote': 'Interested in Class 10 admission',
          'visitDate': '2026-08-20T00:00:00.000Z',
          'status': 'pending',
          'createdBy': 'a1',
        },
      }, 201),
    );

    final result = await repository.createFollowup(
      studentName: 'Sam Prospect',
      faculty: 'Science',
      email: 'sam@test.dev',
      contactNumber: '9800000000',
      address: 'Kathmandu',
      followUpNote: 'Interested in Class 10 admission',
    );

    result.when(
      success: (created) {
        expect(created.studentName, 'Sam Prospect');
        expect(created.createdByName, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createFollowup(): a missing required field (400) surfaces the backend message', () async {
    fakeAdapter.when(
      '/admin/student-followups',
      (_) => jsonResponseBody({
        'success': false,
        'message': 'studentName, faculty, email, contactNumber, address and followUpNote are all required',
      }, 400),
    );

    final result = await repository.createFollowup(
      studentName: 'Sam',
      faculty: '',
      email: '',
      contactNumber: '',
      address: '',
      followUpNote: '',
    );

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('are all required')),
    );
  });

  test('updateFollowup(): puts only the provided fields and parses the updated record', () async {
    fakeAdapter.when(
      '/admin/student-followups/f1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'f1',
          'studentName': 'Sam Prospect',
          'faculty': 'Science',
          'email': 'sam@test.dev',
          'contactNumber': '9800000000',
          'address': 'Kathmandu',
          'followUpNote': 'Interested in Class 10 admission',
          'visitDate': '2026-08-20T00:00:00.000Z',
          'status': 'resolved',
          'createdBy': 'a1',
        },
      }, 200),
    );

    final result = await repository.updateFollowup(id: 'f1', status: 'resolved');

    result.when(
      success: (updated) => expect(updated.status, 'resolved'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteFollowup(): success returns no data', () async {
    fakeAdapter.when('/admin/student-followups/f1', (_) => jsonResponseBody({'success': true, 'message': 'Follow-up record deleted successfully'}, 200));

    final result = await repository.deleteFollowup('f1');

    expect(result.isSuccess, isTrue);
  });

  test('deleteFollowup(): not found (404) surfaces the backend message', () async {
    fakeAdapter.when('/admin/student-followups/f1', (_) => jsonResponseBody({'message': 'Follow-up record not found'}, 404));

    final result = await repository.deleteFollowup('f1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'Follow-up record not found'),
    );
  });

  test('exportFollowups(): returns the raw bytes', () async {
    fakeAdapter.when('/admin/student-followups/export', (_) => bytesResponseBody([5, 6, 7], 200));

    final result = await repository.exportFollowups();

    result.when(
      success: (bytes) => expect(bytes, [5, 6, 7]),
      failure: (_) => fail('expected success'),
    );
  });
}
