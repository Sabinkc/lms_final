import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_correction.dart';
import 'attendance_correction_repository.dart';

class AttendanceCorrectionRepositoryHttp implements AttendanceCorrectionRepository {
  final ApiClient _apiClient;

  AttendanceCorrectionRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<AttendanceCorrection>>> getCorrections({String? status}) async {
    try {
      final corrections = await _apiClient.get<List<AttendanceCorrection>>(
        '/attendance/corrections',
        queryParameters: {if (status != null) 'status': status},
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => AttendanceCorrection.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(corrections);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AttendanceCorrection>> approve(String id, {String? reviewNote}) async {
    try {
      final correction = await _apiClient.patch<AttendanceCorrection>(
        '/attendance/corrections/$id/approve',
        data: {if (reviewNote != null && reviewNote.isNotEmpty) 'reviewNote': reviewNote},
        parse: (data) => AttendanceCorrection.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(correction);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AttendanceCorrection>> reject(String id, {String? reviewNote}) async {
    try {
      final correction = await _apiClient.patch<AttendanceCorrection>(
        '/attendance/corrections/$id/reject',
        data: {if (reviewNote != null && reviewNote.isNotEmpty) 'reviewNote': reviewNote},
        parse: (data) => AttendanceCorrection.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(correction);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
