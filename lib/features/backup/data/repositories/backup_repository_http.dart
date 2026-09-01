import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import 'backup_repository.dart';

class BackupRepositoryHttp implements BackupRepository {
  final ApiClient _apiClient;

  BackupRepositoryHttp(this._apiClient);

  @override
  Future<Result<Uint8List>> downloadSchoolBackup() async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/backup/school',
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
