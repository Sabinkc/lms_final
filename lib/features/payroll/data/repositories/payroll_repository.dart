import '../../../../core/error/result.dart';
import '../models/payroll.dart';
import '../models/staff_salary_config.dart';

/// `/api/payroll` — scoped to `Teacher | Admin | Receptionist` per
/// `payrollSchema.js` (`staffModel`). This app only ever creates
/// `staffModel: "Teacher"` records — Receptionist isn't a modeled role here
/// (product decision #4, `production_roadmap.md` §4), and `getMyPayslips`
/// itself doesn't even resolve an Admin caller to a staff record (it only
/// checks the `Teacher`/`Receptionist` collections), so an `Admin`-model
/// payroll record could never be viewed via self-service anyway.
abstract class PayrollRepository {
  Future<Result<StaffSalaryConfig>> setStaffSalary({
    required String staffId,
    required double basicSalary,
    PayrollAllowances? allowances,
    double? pfRate,
    double? taxRate,
    int? workingDays,
  });

  Future<Result<List<StaffSalaryConfig>>> getSalaryConfigs();

  Future<Result<Payroll>> generatePayroll({
    required String staffId,
    required int month,
    required int year,
    int? absentDays,
    String? remarks,
  });

  /// `(generated, skipped, failed)` counts from the bulk-run response.
  Future<Result<(int, int, int)>> generateBulkPayroll({required int month, required int year});

  Future<Result<Payroll>> markAsPaid(String id, {String? paymentMethod, String? remarks});

  /// `(summary, payrolls)`.
  Future<Result<(PayrollSummary, List<Payroll>)>> getAllPayrolls({int? month, int? year, String? status});

  Future<Result<Payroll>> updatePayroll(String id, {int? absentDays, String? remarks});

  Future<Result<void>> deletePayroll(String id);

  /// Teacher self-service.
  Future<Result<List<Payroll>>> getMyPayslips();
}
