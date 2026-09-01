/// Shape confirmed by reading `payrollSchema.js`/`payrollController.js`
/// directly. Every list/detail endpoint attaches a `staff` object built
/// server-side from `getStaffInfo()` (not a Mongoose populate, since
/// `staffId` is a polymorphic `refPath: staffModel` reference) —
/// `{_id, name, email, model}` — always present on `GET /` and `GET
/// /slip/:id`, absent on the raw `create`/`update`/`mark-paid` responses
/// (those just echo the saved `Payroll` document), so [staffName]/
/// [staffEmail] are nullable.
class Payroll {
  final String id;
  final String staffId;
  final String staffModel;
  final String? staffName;
  final String? staffEmail;
  final int month;
  final int year;
  final double basicSalary;
  final PayrollAllowances allowances;
  final PayrollDeductions deductions;
  final double totalAllowances;
  final double totalDeductions;
  final double grossSalary;
  final double netSalary;
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final String status;
  final String? paidAt;
  final String paymentMethod;
  final String remarks;

  const Payroll({
    required this.id,
    required this.staffId,
    required this.staffModel,
    required this.staffName,
    required this.staffEmail,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.grossSalary,
    required this.netSalary,
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.status,
    required this.paidAt,
    required this.paymentMethod,
    required this.remarks,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] as Map<String, dynamic>?;
    return Payroll(
      id: json['_id'] as String? ?? json['id'] as String,
      staffId: json['staffId'] as String? ?? '',
      staffModel: json['staffModel'] as String? ?? 'Teacher',
      staffName: staff?['name'] as String?,
      staffEmail: staff?['email'] as String?,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0,
      allowances: PayrollAllowances.fromJson(json['allowances'] as Map<String, dynamic>? ?? const {}),
      deductions: PayrollDeductions.fromJson(json['deductions'] as Map<String, dynamic>? ?? const {}),
      totalAllowances: (json['totalAllowances'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0,
      workingDays: (json['workingDays'] as num?)?.toInt() ?? 26,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 26,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paidAt'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      remarks: json['remarks'] as String? ?? '',
    );
  }
}

class PayrollAllowances {
  final double houseRent;
  final double transport;
  final double medical;
  final double other;

  const PayrollAllowances({
    required this.houseRent,
    required this.transport,
    required this.medical,
    required this.other,
  });

  factory PayrollAllowances.fromJson(Map<String, dynamic> json) => PayrollAllowances(
        houseRent: (json['houseRent'] as num?)?.toDouble() ?? 0,
        transport: (json['transport'] as num?)?.toDouble() ?? 0,
        medical: (json['medical'] as num?)?.toDouble() ?? 0,
        other: (json['other'] as num?)?.toDouble() ?? 0,
      );
}

class PayrollDeductions {
  final double tax;
  final double providentFund;
  final double absence;
  final double loan;
  final double other;

  const PayrollDeductions({
    required this.tax,
    required this.providentFund,
    required this.absence,
    required this.loan,
    required this.other,
  });

  factory PayrollDeductions.fromJson(Map<String, dynamic> json) => PayrollDeductions(
        tax: (json['tax'] as num?)?.toDouble() ?? 0,
        providentFund: (json['providentFund'] as num?)?.toDouble() ?? 0,
        absence: (json['absence'] as num?)?.toDouble() ?? 0,
        loan: (json['loan'] as num?)?.toDouble() ?? 0,
        other: (json['other'] as num?)?.toDouble() ?? 0,
      );
}

/// `GET /payroll/summary` doesn't exist — `GET /` (Admin, `getAllPayrolls`)
/// returns this `summary` block alongside `data`, computed from that same
/// filtered list server-side.
class PayrollSummary {
  final double totalNetSalary;
  final double totalPaid;
  final double totalPending;

  const PayrollSummary({required this.totalNetSalary, required this.totalPaid, required this.totalPending});

  factory PayrollSummary.fromJson(Map<String, dynamic> json) => PayrollSummary(
        totalNetSalary: (json['totalNetSalary'] as num?)?.toDouble() ?? 0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
        totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
      );
}
