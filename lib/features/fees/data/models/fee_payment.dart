/// Shape confirmed by reading `paymentSchema.js`/`paymentController.js`
/// directly. Populated fields (`feeId.title`, `studentId.*`,
/// `submittedBy.fullName/email`) are only present on the Admin-facing list
/// endpoints (`GET /payments/fee/pending`, `GET /payments/history`) — a
/// caller's own `GET /payments/my-payments` result populates the same
/// fields, so [fromJson] treats them as always-optional rather than
/// endpoint-specific.
class FeePayment {
  final String id;
  final String feeId;
  final String? feeTitle;
  final String? installmentId;
  final String studentId;
  final String? studentAdmissionNumber;
  final String? submittedByName;
  final double amount;
  final String method;
  final String phoneNumber;
  final String transactionPin;
  final String status;
  final String? rejectionNote;
  final String? reviewedAt;
  final String createdAt;

  const FeePayment({
    required this.id,
    required this.feeId,
    required this.feeTitle,
    required this.installmentId,
    required this.studentId,
    required this.studentAdmissionNumber,
    required this.submittedByName,
    required this.amount,
    required this.method,
    required this.phoneNumber,
    required this.transactionPin,
    required this.status,
    required this.rejectionNote,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    final feeRef = json['feeId'];
    final feeMap = feeRef is Map<String, dynamic> ? feeRef : null;
    final studentRef = json['studentId'];
    final studentMap = studentRef is Map<String, dynamic> ? studentRef : null;
    final submittedByRef = json['submittedBy'];
    final submittedByMap = submittedByRef is Map<String, dynamic> ? submittedByRef : null;

    return FeePayment(
      id: json['_id'] as String? ?? json['id'] as String,
      feeId: feeMap != null ? feeMap['_id'] as String? ?? '' : feeRef as String? ?? '',
      feeTitle: feeMap?['title'] as String?,
      installmentId: json['installmentId'] as String?,
      studentId: studentMap != null ? studentMap['_id'] as String? ?? '' : studentRef as String? ?? '',
      studentAdmissionNumber: studentMap?['admissionNumber'] as String?,
      submittedByName: submittedByMap?['fullName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: json['method'] as String? ?? 'esewa',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      transactionPin: json['transactionPin'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionNote: json['rejectionNote'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
