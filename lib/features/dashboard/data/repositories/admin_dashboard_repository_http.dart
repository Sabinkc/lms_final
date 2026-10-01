import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_overview.dart';
import 'admin_dashboard_repository.dart';

class AdminDashboardRepositoryHttp implements AdminDashboardRepository {
  final ApiClient _apiClient;

  AdminDashboardRepositoryHttp(this._apiClient);

  @override
  Future<Result<AdminDashboardStats>> getStats() async {
    try {
      final stats = await _apiClient.get<AdminDashboardStats>(
        '/admin/dashboard/stats',
        parse: (data) => AdminDashboardStats.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(stats);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<UpcomingExamSummary>>> getUpcomingExams({int limit = 50}) async {
    try {
      final exams = await _apiClient.get<List<UpcomingExamSummary>>(
        '/admin/dashboard/exams',
        queryParameters: {'limit': limit},
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((e) => UpcomingExamSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(exams);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
