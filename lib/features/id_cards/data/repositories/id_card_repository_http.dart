import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import 'id_card_repository.dart';

class IdCardRepositoryHttp implements IdCardRepository {
  final ApiClient _apiClient;

  IdCardRepositoryHttp(this._apiClient);

  @override
  Future<Result<Uint8List>> generateStudentIdCard(String studentId) async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/id-cards/student/$studentId',
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Uint8List>> generateMyIdCard() async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/id-cards/my',
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
