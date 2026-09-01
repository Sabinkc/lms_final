import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/payroll.dart';
import '../models/staff_salary_config.dart';
import 'payroll_repository.dart';

/// Every write here hardcodes `staffModel: "Teacher"` — see
/// [PayrollRepository]'s doc comment for why this app never generates an
/// `Admin`/`Receptionist` payroll record.
class PayrollRepositoryHttp implements PayrollRepository {
  final ApiClient _apiClient;

  PayrollRepositoryHttp(this._apiClient);

  Map<String, dynamic> _allowancesJson(PayrollAllowances a) => {
        'houseRent': a.houseRent,
        'transport': a.transport,
        'medical': a.medical,
        'other': a.other,
      };

  @override
  Future<Result<StaffSalaryConfig>> setStaffSalary({
    required String staffId,
    required double basicSalary,
    PayrollAllowances? allowances,
    double? pfRate,
    double? taxRate,
    int? workingDays,
  }) async {
    try {
      final config = await _apiClient.post<StaffSalaryConfig>(
        '/payroll/salary-config',
        data: {
          'staffId': staffId,
          'staffModel': 'Teacher',
          'basicSalary': basicSalary,
          if (allowances != null) 'allowances': _allowancesJson(allowances),
          if (pfRate != null) 'pfRate': pfRate,
          if (taxRate != null) 'taxRate': taxRate,
          if (workingDays != null) 'workingDays': workingDays,
        },
        parse: (data) => StaffSalaryConfig.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(config);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<StaffSalaryConfig>>> getSalaryConfigs() async {
    try {
      final configs = await _apiClient.get<List<StaffSalaryConfig>>(
        '/payroll/salary-config',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => StaffSalaryConfig.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(configs);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Payroll>> generatePayroll({
    required String staffId,
    required int month,
    required int year,
    int? absentDays,
    String? remarks,
  }) async {
    try {
      final payroll = await _apiClient.post<Payroll>(
        '/payroll/generate',
        data: {
          'staffId': staffId,
          'staffModel': 'Teacher',
          'month': month,
          'year': year,
          if (absentDays != null) 'absentDays': absentDays,
          if (remarks != null) 'remarks': remarks,
        },
        parse: (data) => Payroll.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payroll);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<(int, int, int)>> generateBulkPayroll({required int month, required int year}) async {
    try {
      final counts = await _apiClient.post<(int, int, int)>(
        '/payroll/generate-bulk',
        data: {'month': month, 'year': year},
        parse: (data) {
          final result = (data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
          return (
            (result['generated'] as num?)?.toInt() ?? 0,
            (result['skipped'] as num?)?.toInt() ?? 0,
            (result['failed'] as num?)?.toInt() ?? 0,
          );
        },
      );
      return Result.success(counts);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Payroll>> markAsPaid(String id, {String? paymentMethod, String? remarks}) async {
    try {
      final payroll = await _apiClient.put<Payroll>(
        '/payroll/$id/mark-paid',
        data: {
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (remarks != null) 'remarks': remarks,
        },
        parse: (data) => Payroll.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payroll);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<(PayrollSummary, List<Payroll>)>> getAllPayrolls({int? month, int? year, String? status}) async {
    try {
      final result = await _apiClient.get<(PayrollSummary, List<Payroll>)>(
        '/payroll',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (status != null) 'status': status,
        },
        parse: (data) {
          final map = data as Map<String, dynamic>;
          final summary = PayrollSummary.fromJson(map['summary'] as Map<String, dynamic>);
          final payrolls = (map['data'] as List).map((json) => Payroll.fromJson(json as Map<String, dynamic>)).toList();
          return (summary, payrolls);
        },
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Payroll>> updatePayroll(String id, {int? absentDays, String? remarks}) async {
    try {
      final payroll = await _apiClient.put<Payroll>(
        '/payroll/$id',
        data: {
          if (absentDays != null) 'absentDays': absentDays,
          if (remarks != null) 'remarks': remarks,
        },
        parse: (data) => Payroll.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payroll);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deletePayroll(String id) async {
    try {
      await _apiClient.delete<void>('/payroll/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Payroll>>> getMyPayslips() async {
    try {
      final payslips = await _apiClient.get<List<Payroll>>(
        '/payroll/my',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Payroll.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(payslips);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
