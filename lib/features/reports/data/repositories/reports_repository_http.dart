import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/academic_report.dart';
import '../models/attendance_report.dart';
import '../models/financial_report.dart';
import '../models/system_report.dart';
import 'reports_repository.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class ReportsRepositoryHttp implements ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepositoryHttp(this._apiClient);

  @override
  Future<Result<AcademicReport>> getAcademicReport() async {
    try {
      final report = await _apiClient.get<AcademicReport>(
        '/reports/academic',
        parse: (data) => AcademicReport.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(report);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<FinancialReport>> getFinancialReport() async {
    try {
      final report = await _apiClient.get<FinancialReport>(
        '/reports/financial',
        parse: (data) => FinancialReport.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(report);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AttendanceReport>> getAttendanceReport({DateTime? startDate, DateTime? endDate}) async {
    try {
      final report = await _apiClient.get<AttendanceReport>(
        '/reports/attendance',
        queryParameters: {
          if (startDate != null) 'startDate': _formatDate(startDate),
          if (endDate != null) 'endDate': _formatDate(endDate),
        },
        parse: (data) => AttendanceReport.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(report);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<SystemReport>> getSystemReport() async {
    try {
      final report = await _apiClient.get<SystemReport>(
        '/reports/system',
        parse: (data) => SystemReport.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(report);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
