import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/admin_dashboard_overview.dart';
import '../../data/repositories/admin_dashboard_repository.dart';

/// Backs the "Today's Overview" section of [AdminHomeScreen] — stats and
/// upcoming exams load independently (mirrors [ReportsProvider]'s pattern)
/// so one slow/failed call doesn't block the other tile from showing.
class AdminDashboardProvider extends ChangeNotifier {
  final AdminDashboardRepository _repository;

  AdminDashboardProvider(this._repository);

  LoadStatus _statsStatus = LoadStatus.initial;
  AdminDashboardStats? _stats;
  AppException? _statsError;

  LoadStatus _examsStatus = LoadStatus.initial;
  List<UpcomingExamSummary> _upcomingExams = const [];
  AppException? _examsError;

  LoadStatus get statsStatus => _statsStatus;
  AdminDashboardStats? get stats => _stats;
  AppException? get statsError => _statsError;

  LoadStatus get examsStatus => _examsStatus;
  List<UpcomingExamSummary> get upcomingExams => _upcomingExams;
  AppException? get examsError => _examsError;

  Future<void> loadOverview() async {
    await Future.wait([_loadStats(), _loadUpcomingExams()]);
  }

  Future<void> _loadStats() async {
    _statsStatus = LoadStatus.loading;
    _statsError = null;
    notifyListeners();

    final result = await _repository.getStats();
    result.when(
      success: (stats) {
        _stats = stats;
        _statsStatus = LoadStatus.success;
      },
      failure: (error) {
        _statsError = error;
        _statsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> _loadUpcomingExams() async {
    _examsStatus = LoadStatus.loading;
    _examsError = null;
    notifyListeners();

    final result = await _repository.getUpcomingExams();
    result.when(
      success: (exams) {
        _upcomingExams = exams;
        _examsStatus = LoadStatus.success;
      },
      failure: (error) {
        _examsError = error;
        _examsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
