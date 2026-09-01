import 'payroll.dart';

/// Shape confirmed by reading `staffSalarySchema.js`/`payrollController.js`
/// (`setStaffSalary`/`getSalaryConfigs`) directly. Must exist before a
/// payroll can be generated for that staff member — `generatePayroll` 404s
/// otherwise. `getSalaryConfigs` attaches the same server-built `staff`
/// object `getAllPayrolls` does; `setStaffSalary`'s own response doesn't.
class StaffSalaryConfig {
  final String id;
  final String staffId;
  final String staffModel;
  final String? staffName;
  final String? staffEmail;
  final double basicSalary;
  final PayrollAllowances allowances;
  final double pfRate;
  final double taxRate;
  final int workingDays;
  final bool isActive;

  const StaffSalaryConfig({
    required this.id,
    required this.staffId,
    required this.staffModel,
    required this.staffName,
    required this.staffEmail,
    required this.basicSalary,
    required this.allowances,
    required this.pfRate,
    required this.taxRate,
    required this.workingDays,
    required this.isActive,
  });

  factory StaffSalaryConfig.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] as Map<String, dynamic>?;
    return StaffSalaryConfig(
      id: json['_id'] as String? ?? json['id'] as String,
      staffId: json['staffId'] as String? ?? '',
      staffModel: json['staffModel'] as String? ?? 'Teacher',
      staffName: staff?['name'] as String?,
      staffEmail: staff?['email'] as String?,
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      allowances: PayrollAllowances.fromJson(json['allowances'] as Map<String, dynamic>? ?? const {}),
      pfRate: (json['pfRate'] as num?)?.toDouble() ?? 10,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 5,
      workingDays: (json['workingDays'] as num?)?.toInt() ?? 26,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
