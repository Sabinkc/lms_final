/// `GET /reports/financial` response shape, confirmed by reading
/// `Reportcontroller.js`'s `getFinancialReport` directly. Fee totals are
/// summed client-side-equivalent on the server from every `Fee` document's
/// `totalAmount`/`paidAmount`/`remainingAmount` — not a separate ledger.
class FinancialReport {
  final double totalInvoiced;
  final double totalCollected;
  final double totalPending;
  final int paidCount;
  final int partialCount;
  final int pendingCount;
  final double payrollTotalNetSalary;
  final double payrollTotalPaid;
  final double payrollTotalPending;
  final int totalPayments;

  const FinancialReport({
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalPending,
    required this.paidCount,
    required this.partialCount,
    required this.pendingCount,
    required this.payrollTotalNetSalary,
    required this.payrollTotalPaid,
    required this.payrollTotalPending,
    required this.totalPayments,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    final feeSummary = json['feeSummary'] as Map<String, dynamic>? ?? const {};
    final payrollSummary = json['payrollSummary'] as Map<String, dynamic>? ?? const {};
    return FinancialReport(
      totalInvoiced: (feeSummary['totalInvoiced'] as num?)?.toDouble() ?? 0,
      totalCollected: (feeSummary['totalCollected'] as num?)?.toDouble() ?? 0,
      totalPending: (feeSummary['totalPending'] as num?)?.toDouble() ?? 0,
      paidCount: (feeSummary['paid'] as num?)?.toInt() ?? 0,
      partialCount: (feeSummary['partial'] as num?)?.toInt() ?? 0,
      pendingCount: (feeSummary['pending'] as num?)?.toInt() ?? 0,
      payrollTotalNetSalary: (payrollSummary['totalNetSalary'] as num?)?.toDouble() ?? 0,
      payrollTotalPaid: (payrollSummary['totalPaid'] as num?)?.toDouble() ?? 0,
      payrollTotalPending: (payrollSummary['totalPending'] as num?)?.toDouble() ?? 0,
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
    );
  }
}
