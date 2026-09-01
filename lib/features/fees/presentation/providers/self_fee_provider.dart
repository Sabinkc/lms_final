import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/data/repositories/student_repository.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../../data/models/fee_payment.dart';
import '../../data/repositories/fee_repository.dart';
import '../../data/repositories/payment_repository.dart';

/// Backs both Student "My Fees" and Parent "Child's Fees" — one provider,
/// mirroring `SelfAttendanceProvider`. Unlike Attendance/Exams there is no
/// combined `/fees/me` endpoint, so the Student path resolves its own
/// `Student._id` via `StudentRepository.getMyProfile()` first, then calls
/// `FeeRepository.getStudentFees` with it — one extra round trip the
/// Attendance/Exam self-service screens didn't need.
class SelfFeeProvider extends ChangeNotifier {
  final FeeRepository _feeRepository;
  final PaymentRepository _paymentRepository;
  final StudentRepository _studentRepository;

  SelfFeeProvider(this._feeRepository, this._paymentRepository, this._studentRepository);

  LoadStatus _childrenStatus = LoadStatus.initial;
  List<Student> _children = const [];
  AppException? _childrenError;
  String? _selectedChildId;

  LoadStatus _feesStatus = LoadStatus.initial;
  FeesSummary? _summary;
  String? _paymentQrUrl;
  List<Fee> _fees = const [];
  AppException? _feesError;

  List<FeePayment> _myPayments = const [];

  bool _isSubmittingPayment = false;
  AppException? _paymentActionError;

  LoadStatus get childrenStatus => _childrenStatus;
  List<Student> get children => _children;
  AppException? get childrenError => _childrenError;
  String? get selectedChildId => _selectedChildId;

  LoadStatus get feesStatus => _feesStatus;
  FeesSummary? get summary => _summary;
  String? get paymentQrUrl => _paymentQrUrl;
  List<Fee> get fees => _fees;
  AppException? get feesError => _feesError;

  List<FeePayment> get myPayments => _myPayments;

  bool get isSubmittingPayment => _isSubmittingPayment;
  AppException? get paymentActionError => _paymentActionError;

  /// The most recent payment submitted for this fee/installment, if any —
  /// used to show a status badge instead of a redundant "Pay" button.
  FeePayment? paymentFor({required String feeId, String? installmentId}) {
    final matches = _myPayments.where((p) => p.feeId == feeId && p.installmentId == installmentId);
    return matches.isEmpty ? null : matches.first;
  }

  /// Student role entry point.
  Future<void> loadOwnFees() async {
    final profileResult = await _studentRepository.getMyProfile();
    await profileResult.when(
      success: (student) => _loadFeesFor(student.id),
      failure: (error) async {
        _feesStatus = LoadStatus.error;
        _feesError = error;
        notifyListeners();
      },
    );
  }

  /// Parent role entry point — auto-selects when there's exactly one child.
  Future<void> loadChildren() async {
    _childrenStatus = LoadStatus.loading;
    _childrenError = null;
    notifyListeners();

    final result = await _feeRepository.getMyChildren();
    await result.when(
      success: (children) async {
        _children = children;
        _childrenStatus = LoadStatus.success;
        notifyListeners();
        if (children.length == 1) await selectChild(children.single.id);
      },
      failure: (error) async {
        _childrenError = error;
        _childrenStatus = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> selectChild(String studentId) async {
    _selectedChildId = studentId;
    await _loadFeesFor(studentId);
  }

  Future<void> _loadFeesFor(String studentId) async {
    _feesStatus = LoadStatus.loading;
    _feesError = null;
    notifyListeners();

    final result = await _feeRepository.getStudentFees(studentId);
    await result.when(
      success: (data) async {
        final (summary, qrUrl, fees) = data;
        _summary = summary;
        _paymentQrUrl = qrUrl;
        _fees = fees;
        _feesStatus = LoadStatus.success;
        notifyListeners();
        await _loadMyPayments();
      },
      failure: (error) async {
        _feesError = error;
        _feesStatus = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> _loadMyPayments() async {
    final result = await _paymentRepository.getMyPayments();
    result.when(
      success: (payments) => _myPayments = payments,
      failure: (_) {},
    );
    notifyListeners();
  }

  Future<bool> submitPayment({
    required String feeId,
    String? installmentId,
    required String phoneNumber,
    required String transactionPin,
  }) async {
    _isSubmittingPayment = true;
    _paymentActionError = null;
    notifyListeners();

    final result = await _paymentRepository.submitFeePayment(
      feeId: feeId,
      installmentId: installmentId,
      phoneNumber: phoneNumber,
      transactionPin: transactionPin,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (payment) => _myPayments = [payment, ..._myPayments],
      failure: (error) => _paymentActionError = error,
    );

    _isSubmittingPayment = false;
    notifyListeners();
    return succeeded;
  }
}
