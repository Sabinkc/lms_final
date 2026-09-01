/// Shape confirmed by reading `feeSchema.js`/`feeController.js` directly.
/// `studentId` comes back in three different shapes depending on which
/// endpoint returned it — a bare id string (`GET /fees/student/:studentId`,
/// no populate at all), a minimally-populated object (`GET /fees/:id`:
/// `admissionNumber class section`, no name), or fully populated (`GET
/// /fees`, Admin-only: adds a nested `userId: {fullName, email}`) — so
/// [fromJson] extracts whatever subset is present into flat nullable
/// fields rather than modeling a nested `Student`, since no single shape is
/// guaranteed.
class Fee {
  final String id;
  final String studentId;
  final String? studentName;
  final String? admissionNumber;
  final String? className;
  final String? section;
  final String title;
  final String description;
  final double totalAmount;
  final double discountPercent;
  final double discountAmount;
  final double paidAmount;
  final double remainingAmount;
  final String dueDate;
  final bool isInstallment;
  final List<FeeInstallment> installments;
  final String status;

  const Fee({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.className,
    required this.section,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.isInstallment,
    required this.installments,
    required this.status,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    final studentRef = json['studentId'];
    final studentMap = studentRef is Map<String, dynamic> ? studentRef : null;
    final user = studentMap?['userId'] as Map<String, dynamic>?;

    return Fee(
      id: json['_id'] as String? ?? json['id'] as String,
      studentId: studentMap != null ? studentMap['_id'] as String? ?? '' : studentRef as String? ?? '',
      studentName: user?['fullName'] as String?,
      admissionNumber: studentMap?['admissionNumber'] as String?,
      className: studentMap?['class'] as String?,
      section: studentMap?['section'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      dueDate: json['dueDate'] as String? ?? '',
      isInstallment: json['isInstallment'] as bool? ?? false,
      installments: (json['installments'] as List?)
              ?.map((i) => FeeInstallment.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class FeeInstallment {
  final String id;
  final int installmentNumber;
  final String title;
  final double amount;
  final String dueDate;
  final double paidAmount;
  final String status;

  const FeeInstallment({
    required this.id,
    required this.installmentNumber,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.paidAmount,
    required this.status,
  });

  factory FeeInstallment.fromJson(Map<String, dynamic> json) => FeeInstallment(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        installmentNumber: (json['installmentNumber'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: json['dueDate'] as String? ?? '',
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'pending',
      );
}

/// `GET /fees/student/:studentId`'s `summary` block — computed server-side
/// from that same student's full fee list, not a separate endpoint.
class FeesSummary {
  final int total;
  final int pending;
  final int partial;
  final int paid;
  final double totalDue;

  const FeesSummary({
    required this.total,
    required this.pending,
    required this.partial,
    required this.paid,
    required this.totalDue,
  });

  factory FeesSummary.fromJson(Map<String, dynamic> json) => FeesSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        partial: (json['partial'] as num?)?.toInt() ?? 0,
        paid: (json['paid'] as num?)?.toInt() ?? 0,
        totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
      );
}
