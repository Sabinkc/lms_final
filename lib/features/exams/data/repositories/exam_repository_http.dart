import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/exam.dart';
import 'exam_repository.dart';

class ExamRepositoryHttp implements ExamRepository {
  final ApiClient _apiClient;

  ExamRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Exam>>> getExamsAsAdmin() async {
    try {
      final exams = await _apiClient.get<List<Exam>>(
        '/exams',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Exam.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(exams);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Exam>>> getMyExams() async {
    try {
      final exams = await _apiClient.get<List<Exam>>(
        '/exams/my',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Exam.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(exams);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Exam>> createExam({
    required String title,
    required String className,
    String? section,
    required List<ExamSubject> subjects,
    required String examDate,
  }) async {
    try {
      final created = await _apiClient.post<Exam>(
        '/exams',
        data: {
          'title': title,
          'className': className,
          if (section != null) 'section': section,
          'subjects': subjects.map((s) => s.toJson()).toList(),
          'examDate': examDate,
        },
        parse: (data) => Exam.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Exam>> updateExam({
    required String id,
    String? title,
    String? className,
    String? section,
    List<ExamSubject>? subjects,
    String? examDate,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<Exam>(
        '/exams/$id',
        data: {
          if (title != null) 'title': title,
          if (className != null) 'className': className,
          if (section != null) 'section': section,
          if (subjects != null) 'subjects': subjects.map((s) => s.toJson()).toList(),
          if (examDate != null) 'examDate': examDate,
          if (status != null) 'status': status,
        },
        parse: (data) => Exam.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteExam(String id) async {
    try {
      await _apiClient.delete<void>('/exams/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
