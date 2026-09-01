import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ExamRepositoryHttp repository;

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

    repository = ExamRepositoryHttp(apiClient);
  });

  test('getExamsAsAdmin(): parses the {success, count, data} envelope including subjects[]', () async {
    fakeAdapter.when(
      '/exams',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'e1',
            'title': 'Mid Term',
            'className': 'Class 10',
            'section': 'A',
            'examDate': '2026-09-01',
            'status': 'upcoming',
            'subjects': [
              {'name': 'Math', 'fullMarks': 100, 'passMarks': 40, 'examDate': '2026-09-01'},
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getExamsAsAdmin();

    result.when(
      success: (exams) {
        expect(exams, hasLength(1));
        expect(exams[0].title, 'Mid Term');
        expect(exams[0].subjects.single.name, 'Math');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyExams(): hits /exams/my', () async {
    fakeAdapter.when(
      '/exams/my',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'e1',
            'title': 'Mid Term',
            'className': 'Class 10',
            'examDate': '2026-09-01',
            'status': 'upcoming',
            'subjects': [],
          },
        ],
      }, 200),
    );

    final result = await repository.getMyExams();

    result.when(
      success: (exams) => expect(exams.single.title, 'Mid Term'),
      failure: (_) => fail('expected success'),
    );
  });

  test('createExam(): posts subjects[] and parses the created exam', () async {
    fakeAdapter.when(
      '/exams',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Exam created. Notified 12 students and 3 teachers.',
        'data': {
          '_id': 'e1',
          'title': 'Mid Term',
          'className': 'Class 10',
          'section': 'A',
          'examDate': '2026-09-01',
          'status': 'upcoming',
          'subjects': [
            {'name': 'Math', 'fullMarks': 100, 'passMarks': 40, 'examDate': '2026-09-01'},
          ],
        },
      }, 201),
    );

    final result = await repository.createExam(
      title: 'Mid Term',
      className: 'Class 10',
      section: 'A',
      examDate: '2026-09-01',
      subjects: const [ExamSubject(name: 'Math', fullMarks: 100, passMarks: 40, examDate: '2026-09-01')],
    );

    result.when(
      success: (created) => expect(created.title, 'Mid Term'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteExam(): success returns no data', () async {
    fakeAdapter.when('/exams/e1', (_) => jsonResponseBody({'success': true, 'message': 'Exam deleted'}, 200));

    final result = await repository.deleteExam('e1');

    expect(result.isSuccess, isTrue);
  });
}
