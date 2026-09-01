import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';
import 'assignment_repository.dart';

class AssignmentRepositoryHttp implements AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Assignment>>> getAssignments() async {
    try {
      final assignments = await _apiClient.get<List<Assignment>>(
        '/assignments',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(assignments);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Assignment>> getAssignmentById(String id) async {
    try {
      final assignment = await _apiClient.get<Assignment>(
        '/assignments/$id',
        parse: (data) => Assignment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(assignment);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Assignment>> createAssignment({
    required String title,
    required String description,
    required String className,
    required String section,
    required String subject,
    required String dueDate,
  }) async {
    try {
      final created = await _apiClient.post<Assignment>(
        '/assignments',
        data: {
          'title': title,
          'description': description,
          'class': className,
          'section': section,
          'subject': subject,
          'dueDate': dueDate,
        },
        parse: (data) => Assignment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Assignment>> updateAssignment({
    required String id,
    String? title,
    String? description,
    String? subject,
    String? dueDate,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.patch<Assignment>(
        '/assignments/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (subject != null) 'subject': subject,
          if (dueDate != null) 'dueDate': dueDate,
          if (status != null) 'status': status,
        },
        parse: (data) => Assignment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteAssignment(String id) async {
    try {
      await _apiClient.delete<void>('/assignments/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AssignmentSubmission>> submitAssignment({
    required String assignmentId,
    String? submissionText,
    List<SubmissionFile> files = const [],
  }) async {
    try {
      final submission = await _apiClient.post<AssignmentSubmission>(
        '/assignments/submit',
        data: FormData.fromMap({
          'assignmentId': assignmentId,
          if (submissionText != null) 'submissionText': submissionText,
          for (final f in files) 'files': MultipartFile.fromBytes(f.bytes, filename: f.filename),
        }),
        parse: (data) =>
            AssignmentSubmission.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(submission);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<AssignmentSubmission>>> getMySubmissions() async {
    try {
      final submissions = await _apiClient.get<List<AssignmentSubmission>>(
        '/assignments/my-submissions',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => AssignmentSubmission.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(submissions);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<AssignmentSubmission>>> getSubmissionsForAssignment(String assignmentId) async {
    try {
      final submissions = await _apiClient.get<List<AssignmentSubmission>>(
        '/assignments/$assignmentId/submissions',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => AssignmentSubmission.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(submissions);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AssignmentSubmission>> gradeSubmission({
    required String submissionId,
    required num marks,
    String? remarks,
  }) async {
    try {
      final submission = await _apiClient.patch<AssignmentSubmission>(
        '/assignments/submissions/$submissionId/grade',
        data: {
          'marks': marks,
          if (remarks != null) 'remarks': remarks,
        },
        parse: (data) =>
            AssignmentSubmission.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(submission);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
