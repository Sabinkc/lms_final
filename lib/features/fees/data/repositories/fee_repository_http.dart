import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/fee.dart';
import 'fee_repository.dart';

class FeeRepositoryHttp implements FeeRepository {
  final ApiClient _apiClient;

  FeeRepositoryHttp(this._apiClient);

  @override
  Future<Result<Fee>> createFee({
    required String studentId,
    required String title,
    String? description,
    required double totalAmount,
    double discountPercent = 0,
    String? dueDate,
    bool isInstallment = false,
    List<FeeInstallmentInput>? installments,
  }) async {
    try {
      final created = await _apiClient.post<Fee>(
        '/fees',
        data: {
          'studentId': studentId,
          'title': title,
          if (description != null) 'description': description,
          'totalAmount': totalAmount,
          'discountPercent': discountPercent,
          if (dueDate != null) 'dueDate': dueDate,
          'isInstallment': isInstallment,
          if (installments != null)
            'installments': [
              for (final i in installments)
                {
                  if (i.title != null) 'title': i.title,
                  'amount': i.amount,
                  'dueDate': i.dueDate,
                },
            ],
        },
        parse: (data) => Fee.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Fee>>> getFees({String? status}) async {
    try {
      final fees = await _apiClient.get<List<Fee>>(
        '/fees',
        queryParameters: {if (status != null) 'status': status},
        parse: (data) =>
            ((data as Map<String, dynamic>)['data'] as List).map((json) => Fee.fromJson(json as Map<String, dynamic>)).toList(),
      );
      return Result.success(fees);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Fee>> getFeeById(String id) async {
    try {
      final fee = await _apiClient.get<Fee>(
        '/fees/$id',
        parse: (data) => Fee.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(fee);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Fee>> updateFee({
    required String id,
    String? title,
    String? description,
    double? totalAmount,
    String? dueDate,
  }) async {
    try {
      final updated = await _apiClient.put<Fee>(
        '/fees/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (totalAmount != null) 'totalAmount': totalAmount,
          if (dueDate != null) 'dueDate': dueDate,
        },
        parse: (data) => Fee.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteFee(String id) async {
    try {
      await _apiClient.delete<void>('/fees/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Uint8List>> exportFees({String? status}) async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/fees/export',
        queryParameters: {if (status != null) 'status': status},
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<(FeesSummary, String?, List<Fee>)>> getStudentFees(String studentId) async {
    try {
      final result = await _apiClient.get<(FeesSummary, String?, List<Fee>)>(
        '/fees/student/$studentId',
        parse: (data) {
          final map = data as Map<String, dynamic>;
          final summary = FeesSummary.fromJson(map['summary'] as Map<String, dynamic>);
          final paymentQrUrl = map['paymentQrUrl'] as String?;
          final fees = (map['data'] as List).map((json) => Fee.fromJson(json as Map<String, dynamic>)).toList();
          return (summary, paymentQrUrl, fees);
        },
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Student>>> getMyChildren() async {
    try {
      final children = await _apiClient.get<List<Student>>(
        '/parents/me',
        parse: (data) {
          final students = (((data as Map<String, dynamic>)['data'] as Map<String, dynamic>)['students'] as List?) ??
              const [];
          return students.map((s) => Student.fromJson(s as Map<String, dynamic>)).toList();
        },
      );
      return Result.success(children);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
