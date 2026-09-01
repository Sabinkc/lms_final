import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/assignments/data/repositories/assignment_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late AssignmentRepositoryHttp repository;

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

    repository = AssignmentRepositoryHttp(apiClient);
  });

  test('getAssignments(): parses the {success, count, data} envelope, role-scoping entirely server-side', () async {
    fakeAdapter.when(
      '/assignments',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'a1',
            'title': 'Algebra Homework',
            'description': 'Chapter 4 exercises',
            'class': 'Class 10',
            'section': 'A',
            'subject': 'Math',
            'dueDate': '2026-09-01',
            'status': 'active',
            'teacherId': {'employeeId': 'EMP001'},
          },
        ],
      }, 200),
    );

    final result = await repository.getAssignments();

    result.when(
      success: (assignments) {
        expect(assignments, hasLength(1));
        expect(assignments[0].title, 'Algebra Homework');
        expect(assignments[0].teacherEmployeeId, 'EMP001');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('createAssignment(): posts class/section as plain strings, not sectionId', () async {
    fakeAdapter.when(
      '/assignments',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Assignment created. Notifying 12 student(s) in Class 10–A.',
        'data': {
          '_id': 'a1',
          'title': 'Algebra Homework',
          'description': 'Chapter 4 exercises',
          'class': 'Class 10',
          'section': 'A',
          'subject': 'Math',
          'dueDate': '2026-09-01',
          'status': 'active',
        },
      }, 201),
    );

    final result = await repository.createAssignment(
      title: 'Algebra Homework',
      description: 'Chapter 4 exercises',
      className: 'Class 10',
      section: 'A',
      subject: 'Math',
      dueDate: '2026-09-01',
    );

    result.when(
      success: (created) => expect(created.title, 'Algebra Homework'),
      failure: (_) => fail('expected success'),
    );
  });

  test('updateAssignment(): patches only the provided fields', () async {
    fakeAdapter.when(
      '/assignments/a1',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Assignment updated successfully',
        'data': {
          '_id': 'a1',
          'title': 'Algebra Homework (updated)',
          'description': 'Chapter 4 exercises',
          'class': 'Class 10',
          'section': 'A',
          'subject': 'Math',
          'dueDate': '2026-09-01',
          'status': 'active',
        },
      }, 200),
    );

    final result = await repository.updateAssignment(id: 'a1', title: 'Algebra Homework (updated)');

    result.when(
      success: (updated) => expect(updated.title, 'Algebra Homework (updated)'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteAssignment(): success returns no data', () async {
    fakeAdapter.when(
      '/assignments/a1',
      (_) => jsonResponseBody({'success': true, 'message': 'Assignment and its submissions deleted successfully'}, 200),
    );

    final result = await repository.deleteAssignment('a1');

    expect(result.isSuccess, isTrue);
  });

  test('submitAssignment(): a past-due first submission (400, confirmed real shape) surfaces the backend message',
      () async {
    fakeAdapter.when(
      '/assignments/submit',
      (_) => jsonResponseBody({'success': false, 'message': 'Assignment due date has passed'}, 400),
    );

    final result = await repository.submitAssignment(assignmentId: 'a1', submissionText: 'My work');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, contains('due date has passed')),
    );
  });

  test('submitAssignment(): success parses the created submission', () async {
    fakeAdapter.when(
      '/assignments/submit',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Assignment submitted successfully',
        'data': {
          '_id': 'sub1',
          'assignmentId': 'a1',
          'submissionText': 'My work',
          'attachments': [],
          'submittedAt': '2026-08-25T00:00:00.000Z',
          'marks': null,
          'remarks': '',
        },
      }, 201),
    );

    final result = await repository.submitAssignment(assignmentId: 'a1', submissionText: 'My work');

    result.when(
      success: (submission) {
        expect(submission.assignmentId, 'a1');
        expect(submission.graded, isFalse);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getSubmissionsForAssignment(): parses populated studentId with nested userId', () async {
    fakeAdapter.when(
      '/assignments/a1/submissions',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'sub1',
            'assignmentId': 'a1',
            'submissionText': 'My work',
            'attachments': [],
            'submittedAt': '2026-08-25T00:00:00.000Z',
            'marks': null,
            'remarks': '',
            'studentId': {
              'admissionNumber': 'ADM001',
              'userId': {'fullName': 'Sam Student', 'email': 'sam@school.test'},
            },
          },
        ],
      }, 200),
    );

    final result = await repository.getSubmissionsForAssignment('a1');

    result.when(
      success: (submissions) => expect(submissions.single.studentName, 'Sam Student'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getMySubmissions(): parses populated assignmentId summary fields', () async {
    fakeAdapter.when(
      '/assignments/my-submissions',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'sub1',
            'assignmentId': {'_id': 'a1', 'title': 'Algebra Homework', 'dueDate': '2026-09-01', 'status': 'active'},
            'submissionText': 'My work',
            'attachments': [],
            'submittedAt': '2026-08-25T00:00:00.000Z',
            'marks': null,
            'remarks': '',
          },
        ],
      }, 200),
    );

    final result = await repository.getMySubmissions();

    result.when(
      success: (submissions) {
        expect(submissions.single.assignmentId, 'a1');
        expect(submissions.single.assignmentTitle, 'Algebra Homework');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('gradeSubmission(): patches marks/remarks and parses the graded submission', () async {
    fakeAdapter.when(
      '/assignments/submissions/sub1/grade',
      (_) => jsonResponseBody({
        'success': true,
        'message': 'Submission graded successfully',
        'data': {
          '_id': 'sub1',
          'assignmentId': 'a1',
          'submissionText': 'My work',
          'attachments': [],
          'submittedAt': '2026-08-25T00:00:00.000Z',
          'marks': 85,
          'remarks': 'Good work',
          'gradedAt': '2026-08-26T00:00:00.000Z',
        },
      }, 200),
    );

    final result = await repository.gradeSubmission(submissionId: 'sub1', marks: 85, remarks: 'Good work');

    result.when(
      success: (submission) {
        expect(submission.marks, 85);
        expect(submission.graded, isTrue);
      },
      failure: (_) => fail('expected success'),
    );
  });
}
