import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/teacher.dart';
import '../../../admin_management/data/repositories/teacher_repository.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../../data/models/staff_salary_config.dart';
import '../../data/repositories/payroll_repository.dart';

/// Admin-only: Salary Config (must exist before a payroll can be generated
/// for that Teacher) plus Payroll generate/list/mark-paid/update/delete —
/// bundled into one provider since they're one Admin workflow, same
/// reasoning as [FeeProvider] bundling Fee CRUD + Payment review.
class PayrollProvider extends ChangeNotifier {
  final PayrollRepository _repository;
  final TeacherRepository _teacherRepository;

  PayrollProvider(this._repository, this._teacherRepository);

  List<Teacher> _teacherOptions = const [];

  LoadStatus _configsStatus = LoadStatus.initial;
  List<StaffSalaryConfig> _configs = const [];
  AppException? _configsError;
  bool _isSavingConfig = false;
  AppException? _configActionError;

  LoadStatus _payrollsStatus = LoadStatus.initial;
  PayrollSummary? _summary;
  List<Payroll> _payrolls = const [];
  AppException? _payrollsError;

  bool _isGenerating = false;
  AppException? _generateError;
  (int, int, int)? _lastBulkResult;

  final Set<String> _processingPayrollIds = {};
  AppException? _payrollActionError;

  List<Teacher> get teacherOptions => _teacherOptions;

  LoadStatus get configsStatus => _configsStatus;
  List<StaffSalaryConfig> get configs => _configs;
  AppException? get configsError => _configsError;
  bool get isSavingConfig => _isSavingConfig;
  AppException? get configActionError => _configActionError;

  LoadStatus get payrollsStatus => _payrollsStatus;
  PayrollSummary? get summary => _summary;
  List<Payroll> get payrolls => _payrolls;
  AppException? get payrollsError => _payrollsError;

  bool get isGenerating => _isGenerating;
  AppException? get generateError => _generateError;
  (int, int, int)? get lastBulkResult => _lastBulkResult;

  bool isProcessingPayroll(String id) => _processingPayrollIds.contains(id);
  AppException? get payrollActionError => _payrollActionError;

  Future<void> loadTeacherOptions() async {
    final result = await _teacherRepository.getTeachers();
    result.when(success: (teachers) => _teacherOptions = teachers, failure: (_) {});
    notifyListeners();
  }

  Future<void> loadSalaryConfigs({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _configsStatus != LoadStatus.success) _configsStatus = LoadStatus.loading;
    _configsError = null;
    notifyListeners();

    final result = await _repository.getSalaryConfigs();
    result.when(
      success: (configs) {
        _configs = configs;
        _configsStatus = LoadStatus.success;
      },
      failure: (error) {
        _configsError = error;
        _configsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> setStaffSalary({
    required String staffId,
    required double basicSalary,
    PayrollAllowances? allowances,
    double? pfRate,
    double? taxRate,
    int? workingDays,
  }) async {
    _isSavingConfig = true;
    _configActionError = null;
    notifyListeners();

    final result = await _repository.setStaffSalary(
      staffId: staffId,
      basicSalary: basicSalary,
      allowances: allowances,
      pfRate: pfRate,
      taxRate: taxRate,
      workingDays: workingDays,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (saved) => _configs = [
        for (final c in _configs)
          if (c.staffId == saved.staffId) saved else c,
        if (!_configs.any((c) => c.staffId == saved.staffId)) saved,
      ],
      failure: (error) => _configActionError = error,
    );

    _isSavingConfig = false;
    notifyListeners();
    return succeeded;
  }

  Future<void> loadPayrolls({int? month, int? year, String? status, bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _payrollsStatus != LoadStatus.success) _payrollsStatus = LoadStatus.loading;
    _payrollsError = null;
    notifyListeners();

    final result = await _repository.getAllPayrolls(month: month, year: year, status: status);
    result.when(
      success: (data) {
        final (summary, payrolls) = data;
        _summary = summary;
        _payrolls = payrolls;
        _payrollsStatus = LoadStatus.success;
      },
      failure: (error) {
        _payrollsError = error;
        _payrollsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> generatePayroll({
    required String staffId,
    required int month,
    required int year,
    int? absentDays,
    String? remarks,
  }) async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    final result = await _repository.generatePayroll(
      staffId: staffId,
      month: month,
      year: year,
      absentDays: absentDays,
      remarks: remarks,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _payrolls = [created, ..._payrolls], failure: (error) => _generateError = error);

    _isGenerating = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> generateBulkPayroll({required int month, required int year}) async {
    _isGenerating = true;
    _generateError = null;
    _lastBulkResult = null;
    notifyListeners();

    final result = await _repository.generateBulkPayroll(month: month, year: year);
    final succeeded = result.isSuccess;
    result.when(success: (counts) => _lastBulkResult = counts, failure: (error) => _generateError = error);

    _isGenerating = false;
    notifyListeners();
    if (succeeded) await loadPayrolls(month: month, year: year);
    return succeeded;
  }

  Future<bool> markAsPaid(String id, {String? paymentMethod, String? remarks}) async {
    _processingPayrollIds.add(id);
    _payrollActionError = null;
    notifyListeners();

    final result = await _repository.markAsPaid(id, paymentMethod: paymentMethod, remarks: remarks);
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _payrolls = [
        for (final p in _payrolls)
          if (p.id == updated.id) updated else p,
      ],
      failure: (error) => _payrollActionError = error,
    );

    _processingPayrollIds.remove(id);
    notifyListeners();
    return succeeded;
  }

  Future<bool> deletePayroll(String id) async {
    _payrollActionError = null;

    final result = await _repository.deletePayroll(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _payrolls = _payrolls.where((p) => p.id != id).toList(),
      failure: (error) => _payrollActionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
