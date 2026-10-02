import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../../data/repositories/payroll_repository.dart';

/// Teacher self-service: `GET /payroll/my`. Real data replaces the "mock
/// trigger" dashboard banner `implementation_backlog.md` E8-F2-T1 describes
/// — once the actual payslip list exists there's no reason to build a mock
/// version first, same call the app made for every other "wire real data"
/// task this phase.
class MyPayslipsProvider extends ChangeNotifier {
  final PayrollRepository _repository;

  MyPayslipsProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<Payroll> _payslips = const [];
  AppException? _error;

  LoadStatus get status => _status;
  List<Payroll> get payslips => _payslips;
  AppException? get error => _error;

  Future<void> loadMyPayslips({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyPayslips();
    result.when(
      success: (payslips) {
        _payslips = payslips;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
