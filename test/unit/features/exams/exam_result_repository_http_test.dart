import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_result_repository.dart';
import 'package:cloud_lms/features/exams/data/repositories/exam_result_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ExamResultRepositoryHttp repository;

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

    repository = ExamResultRepositoryHttp(apiClient);
  });

  test('publishResults(): posts examId + results[] to /results/publish', () async {
    fakeAdapter.when(
      '/results/publish',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Results published: 1 success, 0 failed',
        'data': {'published': 1, 'failed': []},
      }, 200),
    );

    final result = await repository.publishResults(
      examId: 'e1',
      results: [
        const StudentResultInput(
          studentId: 's1',
          marks: [ResultMarkInput(subject: 'Math', obtainedMarks: 85, fullMarks: 100, passMarks: 40)],
        ),
      ],
    );

    expect(result.isSuccess, isTrue);
  });

  test('getExamResults(): parses summary + ranked results list', () async {
    fakeAdapter.when(
      '/results/exam/e1',
      (_) => jsonResponseBody({
        'success': true,
        'exam': {'title': 'Mid Term', 'className': 'Class 10', 'section': 'A'},
        'summary': {'total': 1, 'passed': 1, 'failed': 0, 'avgPercentage': 85.0, 'gradeDistribution': {'A': 1}},
        'data': [
          {
            '_id': 'r1',
            'examId': {'_id': 'e1', 'title': 'Mid Term'},
            'studentId': {
              '_id': 's1',
              'admissionNumber': 'ADM001',
              'userId': {'fullName': 'Sam Student'},
            },
            'marks': [
              {'subject': 'Math', 'fullMarks': 100, 'passMarks': 40, 'obtainedMarks': 85, 'isPassed': true, 'grade': 'A'},
            ],
            'totalObtained': 85,
            'totalFull': 100,
            'percentage': 85.0,
            'grade': 'A',
            'isPassed': true,
            'rank': 1,
            'remarks': '',
          },
        ],
      }, 200),
    );

    final result = await repository.getExamResults('e1');

    result.when(
      success: (data) {
        final (summary, results) = data;
        expect(summary.total, 1);
        expect(summary.gradeDistribution['A'], 1);
        expect(results.single.studentName, 'Sam Student');
        expect(results.single.rank, 1);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyResults(): parses populated examId title', () async {
    fakeAdapter.when(
      '/results/my',
      (_) => jsonResponseBody({
        'success': true,
        'summary': {'totalExams': 1, 'passed': 1, 'failed': 0, 'averagePercentage': 85.0, 'bestGrade': 'A'},
        'data': [
          {
            '_id': 'r1',
            'examId': {'_id': 'e1', 'title': 'Mid Term'},
            'marks': [],
            'totalObtained': 85,
            'totalFull': 100,
            'percentage': 85.0,
            'grade': 'A',
            'isPassed': true,
            'remarks': '',
          },
        ],
      }, 200),
    );

    final result = await repository.getMyResults();

    result.when(
      success: (results) => expect(results.single.examTitle, 'Mid Term'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyResultForExam(): a not-yet-published exam (404, confirmed real shape) surfaces the backend message',
      () async {
    fakeAdapter.when(
      '/results/my/e1',
      (_) => jsonResponseBody({'success': false, 'message': 'Result not found or not published yet'}, 404),
    );

    final result = await repository.getMyResultForExam('e1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('not published yet')),
    );
  });

  test('getReportCard(): parses the nested school/exam/student/summary shape', () async {
    fakeAdapter.when(
      '/results/report-card/e1/s1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'school': {'name': 'Greenwood Demo School'},
          'exam': {'title': 'Mid Term'},
          'student': {'name': 'Sam Student', 'admissionNumber': 'ADM001', 'rollNumber': '1', 'class': 'Class 10', 'section': 'A'},
          'marks': [
            {'subject': 'Math', 'fullMarks': 100, 'passMarks': 40, 'obtainedMarks': 85, 'isPassed': true, 'grade': 'A'},
          ],
          'summary': {
            'totalObtained': 85,
            'totalFull': 100,
            'percentage': 85.0,
            'grade': 'A',
            'rank': 1,
            'isPassed': true,
            'remarks': '',
          },
        },
      }, 200),
    );

    final result = await repository.getReportCard(examId: 'e1', studentId: 's1');

    result.when(
      success: (card) {
        expect(card.schoolName, 'Greenwood Demo School');
        expect(card.studentName, 'Sam Student');
        expect(card.rank, 1);
      },
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
          'userId': {'fullName': 'Pat Parent'},
          'students': [
            {
              '_id': 's1',
              'userId': {'fullName': 'Sam Student'},
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

  test('getChildResults(): hits /results/child/:studentId', () async {
    fakeAdapter.when(
      '/results/child/s1',
      (_) => jsonResponseBody({
        'success': true,
        'summary': {'totalExams': 1, 'passed': 1, 'failed': 0, 'averagePercentage': 85.0},
        'data': [
          {
            '_id': 'r1',
            'examId': {'_id': 'e1', 'title': 'Mid Term'},
            'marks': [],
            'totalObtained': 85,
            'totalFull': 100,
            'percentage': 85.0,
            'grade': 'A',
            'isPassed': true,
            'remarks': '',
          },
        ],
      }, 200),
    );

    final result = await repository.getChildResults('s1');

    result.when(
      success: (results) => expect(results.single.examId, 'e1'),
      failure: (_) => fail('expected success'),
    );
  });
}
