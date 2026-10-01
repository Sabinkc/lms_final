import '../../../../core/error/result.dart';
import '../models/admin_dashboard_overview.dart';

abstract class AdminDashboardRepository {
  Future<Result<AdminDashboardStats>> getStats();

  /// `limit` capped generously (not paginated) since this only backs a
  /// single home-screen count tile plus the "next exam" caption — not a
  /// list screen.
  Future<Result<List<UpcomingExamSummary>>> getUpcomingExams({int limit = 50});
}
