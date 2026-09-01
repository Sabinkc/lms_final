import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/academic_report.dart';
import '../../data/models/attendance_report.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/system_report.dart';
import '../../data/repositories/reports_repository.dart';

/// Admin-only Reports Dashboard (`implementation_backlog.md` E12) — four
/// independent aggregate categories, each with its own load status so a
/// slow/failed report doesn't block another tab from showing, mirroring how
/// [PayrollProvider] bundles more than one Admin workflow into one provider
/// rather than one-provider-per-tab.
class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository;

  ReportsProvider(this._repository);

  LoadStatus _academicStatus = LoadStatus.initial;
  AcademicReport? _academic;
  AppException? _academicError;

  LoadStatus _financialStatus = LoadStatus.initial;
  FinancialReport? _financial;
  AppException? _financialError;

  LoadStatus _attendanceStatus = LoadStatus.initial;
  AttendanceReport? _attendance;
  AppException? _attendanceError;
  DateTime? _attendanceStartDate;
  DateTime? _attendanceEndDate;

  LoadStatus _systemStatus = LoadStatus.initial;
  SystemReport? _system;
  AppException? _systemError;

  LoadStatus get academicStatus => _academicStatus;
  AcademicReport? get academic => _academic;
  AppException? get academicError => _academicError;

  LoadStatus get financialStatus => _financialStatus;
  FinancialReport? get financial => _financial;
  AppException? get financialError => _financialError;

  LoadStatus get attendanceStatus => _attendanceStatus;
  AttendanceReport? get attendance => _attendance;
  AppException? get attendanceError => _attendanceError;
  DateTime? get attendanceStartDate => _attendanceStartDate;
  DateTime? get attendanceEndDate => _attendanceEndDate;

  LoadStatus get systemStatus => _systemStatus;
  SystemReport? get system => _system;
  AppException? get systemError => _systemError;

  Future<void> loadAcademic() async {
    _academicStatus = LoadStatus.loading;
    _academicError = null;
    notifyListeners();

    final result = await _repository.getAcademicReport();
    result.when(
      success: (report) {
        _academic = report;
        _academicStatus = LoadStatus.success;
      },
      failure: (error) {
        _academicError = error;
        _academicStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadFinancial() async {
    _financialStatus = LoadStatus.loading;
    _financialError = null;
    notifyListeners();

    final result = await _repository.getFinancialReport();
    result.when(
      success: (report) {
        _financial = report;
        _financialStatus = LoadStatus.success;
      },
      failure: (error) {
        _financialError = error;
        _financialStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadAttendance({DateTime? startDate, DateTime? endDate}) async {
    _attendanceStatus = LoadStatus.loading;
    _attendanceError = null;
    _attendanceStartDate = startDate;
    _attendanceEndDate = endDate;
    notifyListeners();

    final result = await _repository.getAttendanceReport(startDate: startDate, endDate: endDate);
    result.when(
      success: (report) {
        _attendance = report;
        _attendanceStatus = LoadStatus.success;
      },
      failure: (error) {
        _attendanceError = error;
        _attendanceStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadSystem() async {
    _systemStatus = LoadStatus.loading;
    _systemError = null;
    notifyListeners();

    final result = await _repository.getSystemReport();
    result.when(
      success: (report) {
        _system = report;
        _systemStatus = LoadStatus.success;
      },
      failure: (error) {
        _systemError = error;
        _systemStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
