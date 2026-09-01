import '../../../../core/error/result.dart';
import '../models/fee_payment.dart';

/// `/api/payments` — the manual-verification fee-payment flow
/// (`api_spec.md` §4.9): a Student/Parent submits the phone number +
/// transaction PIN their eSewa/Khalti/bank-transfer app showed after
/// paying; an Admin cross-checks it manually and approves/rejects.
abstract class PaymentRepository {
  Future<Result<FeePayment>> submitFeePayment({
    required String feeId,
    String? installmentId,
    required String phoneNumber,
    required String transactionPin,
  });

  /// Admin-only pending review queue.
  Future<Result<List<FeePayment>>> getPendingPayments();

  Future<Result<FeePayment>> approvePayment(String paymentId);

  Future<Result<FeePayment>> rejectPayment(String paymentId, {String? note});

  /// Admin → every payment for the school. Student/Parent → only what they
  /// personally submitted (`paymentController.js`'s `getPayments`: filter is
  /// `req.admin ? {schoolId} : {submittedBy: req.user._id}` — the same
  /// route, `GET /payments/history` vs. `GET /payments/my-payments`, just
  /// scoped differently server-side by which auth guard matched).
  Future<Result<List<FeePayment>>> getPaymentHistory();

  Future<Result<List<FeePayment>>> getMyPayments();
}
