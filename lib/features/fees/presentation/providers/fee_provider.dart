import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/data/repositories/student_repository.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../../data/models/fee_payment.dart';
import '../../data/repositories/fee_repository.dart';
import '../../data/repositories/payment_repository.dart';

/// Admin-only: Fee Structure Setup (E7-F1) plus the pending-payments review
/// queue (E7-F2) — kept as one provider since both are the same Admin
/// actor's fee-management workflow, mirroring how [AdminAttendanceProvider]
/// bundles Overview + Corrections despite reading two repositories.
class FeeProvider extends ChangeNotifier {
  final FeeRepository _feeRepository;
  final PaymentRepository _paymentRepository;
  final StudentRepository _studentRepository;

  FeeProvider(this._feeRepository, this._paymentRepository, this._studentRepository);

  LoadStatus _status = LoadStatus.initial;
  List<Fee> _fees = const [];
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  bool _isDownloading = false;
  AppException? _downloadError;

  List<Student> _studentOptions = const [];

  LoadStatus _pendingStatus = LoadStatus.initial;
  List<FeePayment> _pendingPayments = const [];
  AppException? _pendingError;

  LoadStatus _historyStatus = LoadStatus.initial;
  List<FeePayment> _history = const [];
  AppException? _historyError;

  final Set<String> _processingPaymentIds = {};
  AppException? _paymentActionError;

  LoadStatus get status => _status;
  List<Fee> get fees => _fees;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  bool get isDownloading => _isDownloading;
  AppException? get downloadError => _downloadError;

  List<Student> get studentOptions => _studentOptions;

  LoadStatus get pendingStatus => _pendingStatus;
  List<FeePayment> get pendingPayments => _pendingPayments;
  AppException? get pendingError => _pendingError;

  LoadStatus get historyStatus => _historyStatus;
  List<FeePayment> get history => _history;
  AppException? get historyError => _historyError;

  bool isProcessingPayment(String id) => _processingPaymentIds.contains(id);
  AppException? get paymentActionError => _paymentActionError;

  Future<void> loadFees({String? status}) async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _feeRepository.getFees(status: status);
    result.when(
      success: (fees) {
        _fees = fees;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadStudentOptions() async {
    final result = await _studentRepository.getStudents();
    result.when(
      success: (students) => _studentOptions = students,
      failure: (_) {},
    );
    notifyListeners();
  }

  Future<bool> createFee({
    required String studentId,
    required String title,
    String? description,
    required double totalAmount,
    double discountPercent = 0,
    String? dueDate,
    bool isInstallment = false,
    List<FeeInstallmentInput>? installments,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _feeRepository.createFee(
      studentId: studentId,
      title: title,
      description: description,
      totalAmount: totalAmount,
      discountPercent: discountPercent,
      dueDate: dueDate,
      isInstallment: isInstallment,
      installments: installments,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (created) => _fees = [created, ..._fees],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateFee({
    required String id,
    String? title,
    String? description,
    double? totalAmount,
    String? dueDate,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result =
        await _feeRepository.updateFee(id: id, title: title, description: description, totalAmount: totalAmount, dueDate: dueDate);
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _fees = [for (final f in _fees) if (f.id == updated.id) updated else f],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteFee(String id) async {
    _actionError = null;

    final result = await _feeRepository.deleteFee(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _fees = _fees.where((f) => f.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }

  Future<void> loadPendingPayments() async {
    _pendingStatus = LoadStatus.loading;
    _pendingError = null;
    notifyListeners();

    final result = await _paymentRepository.getPendingPayments();
    result.when(
      success: (payments) {
        _pendingPayments = payments;
        _pendingStatus = LoadStatus.success;
      },
      failure: (error) {
        _pendingError = error;
        _pendingStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _historyStatus = LoadStatus.loading;
    _historyError = null;
    notifyListeners();

    final result = await _paymentRepository.getPaymentHistory();
    result.when(
      success: (payments) {
        _history = payments;
        _historyStatus = LoadStatus.success;
      },
      failure: (error) {
        _historyError = error;
        _historyStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> approvePayment(String id) async {
    _processingPaymentIds.add(id);
    _paymentActionError = null;
    notifyListeners();

    final result = await _paymentRepository.approvePayment(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _pendingPayments = _pendingPayments.where((p) => p.id != id).toList(),
      failure: (error) => _paymentActionError = error,
    );

    _processingPaymentIds.remove(id);
    notifyListeners();
    return succeeded;
  }

  Future<bool> rejectPayment(String id, {String? note}) async {
    _processingPaymentIds.add(id);
    _paymentActionError = null;
    notifyListeners();

    final result = await _paymentRepository.rejectPayment(id, note: note);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _pendingPayments = _pendingPayments.where((p) => p.id != id).toList(),
      failure: (error) => _paymentActionError = error,
    );

    _processingPaymentIds.remove(id);
    notifyListeners();
    return succeeded;
  }

  /// `docs/production_roadmap.md` Phase L3 — same `StudentProvider
  /// .exportStudents()` shape.
  Future<Uint8List?> exportFees({String? status}) async {
    _isDownloading = true;
    _downloadError = null;
    notifyListeners();

    final result = await _feeRepository.exportFees(status: status);
    _isDownloading = false;
    Uint8List? bytes;
    result.when(
      success: (data) => bytes = data,
      failure: (error) => _downloadError = error,
    );
    notifyListeners();
    return bytes;
  }
}
