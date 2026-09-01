import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/fee_payment.dart';
import 'payment_repository.dart';

class PaymentRepositoryHttp implements PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepositoryHttp(this._apiClient);

  @override
  Future<Result<FeePayment>> submitFeePayment({
    required String feeId,
    String? installmentId,
    required String phoneNumber,
    required String transactionPin,
  }) async {
    try {
      final payment = await _apiClient.post<FeePayment>(
        '/payments/fee/submit',
        data: {
          'feeId': feeId,
          if (installmentId != null) 'installmentId': installmentId,
          'phoneNumber': phoneNumber,
          'transactionPin': transactionPin,
        },
        parse: (data) => FeePayment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payment);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<FeePayment>>> getPendingPayments() async {
    try {
      final payments = await _apiClient.get<List<FeePayment>>(
        '/payments/fee/pending',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => FeePayment.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(payments);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<FeePayment>> approvePayment(String paymentId) async {
    try {
      final payment = await _apiClient.post<FeePayment>(
        '/payments/fee/approve/$paymentId',
        parse: (data) => FeePayment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payment);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<FeePayment>> rejectPayment(String paymentId, {String? note}) async {
    try {
      final payment = await _apiClient.post<FeePayment>(
        '/payments/fee/reject/$paymentId',
        data: {if (note != null) 'note': note},
        parse: (data) => FeePayment.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(payment);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<FeePayment>>> getPaymentHistory() async {
    try {
      final payments = await _apiClient.get<List<FeePayment>>(
        '/payments/history',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => FeePayment.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(payments);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<FeePayment>>> getMyPayments() async {
    try {
      final payments = await _apiClient.get<List<FeePayment>>(
        '/payments/my-payments',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => FeePayment.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(payments);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
