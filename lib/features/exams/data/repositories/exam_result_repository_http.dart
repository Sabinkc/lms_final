import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/exam_result.dart';
import 'exam_result_repository.dart';

class ExamResultRepositoryHttp implements ExamResultRepository {
  final ApiClient _apiClient;

  ExamResultRepositoryHttp(this._apiClient);

  @override
  Future<Result<void>> publishResults({
    required String examId,
    required List<StudentResultInput> results,
  }) async {
    try {
      await _apiClient.post<void>(
        '/results/publish',
        data: {
          'examId': examId,
          'results': [
            for (final r in results)
              {
                'studentId': r.studentId,
                'marks': [
                  for (final m in r.marks)
                    {
                      'subject': m.subject,
                      'obtainedMarks': m.obtainedMarks,
                      'fullMarks': m.fullMarks,
                      'passMarks': m.passMarks,
                    },
                ],
                if (r.remarks != null && r.remarks!.isNotEmpty) 'remarks': r.remarks,
              },
          ],
        },
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<(ClassResultsSummary, List<ExamResult>)>> getExamResults(String examId) async {
    try {
      final combined = await _apiClient.get<(ClassResultsSummary, List<ExamResult>)>(
        '/results/exam/$examId',
        parse: (data) {
          final map = data as Map<String, dynamic>;
          final summary = ClassResultsSummary.fromJson(map['summary'] as Map<String, dynamic>);
          final results = (map['data'] as List).map((r) => ExamResult.fromJson(r as Map<String, dynamic>)).toList();
          return (summary, results);
        },
      );
      return Result.success(combined);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ResultsSummary>> getMyResultsSummary() async {
    try {
      final summary = await _apiClient.get<ResultsSummary>(
        '/results/my',
        parse: (data) => ResultsSummary.fromJson((data as Map<String, dynamic>)['summary'] as Map<String, dynamic>),
      );
      return Result.success(summary);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<ExamResult>>> getMyResults() async {
    try {
      final results = await _apiClient.get<List<ExamResult>>(
        '/results/my',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => ExamResult.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(results);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ExamResult>> getMyResultForExam(String examId) async {
    try {
      final result = await _apiClient.get<ExamResult>(
        '/results/my/$examId',
        parse: (data) => ExamResult.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ReportCard>> getReportCard({required String examId, required String studentId}) async {
    try {
      final reportCard = await _apiClient.get<ReportCard>(
        '/results/report-card/$examId/$studentId',
        parse: (data) => ReportCard.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(reportCard);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Student>>> getMyChildren() async {
    try {
      final children = await _apiClient.get<List<Student>>(
        '/parents/me',
        parse: (data) {
          final students = (((data as Map<String, dynamic>)['data'] as Map<String, dynamic>)['students'] as List?) ??
              const [];
          return students.map((s) => Student.fromJson(s as Map<String, dynamic>)).toList();
        },
      );
      return Result.success(children);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ResultsSummary>> getChildResultsSummary(String studentId) async {
    try {
      final summary = await _apiClient.get<ResultsSummary>(
        '/results/child/$studentId',
        parse: (data) => ResultsSummary.fromJson((data as Map<String, dynamic>)['summary'] as Map<String, dynamic>),
      );
      return Result.success(summary);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<ExamResult>>> getChildResults(String studentId) async {
    try {
      final results = await _apiClient.get<List<ExamResult>>(
        '/results/child/$studentId',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => ExamResult.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(results);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
