import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/student_followup.dart';
import 'student_followup_repository.dart';

class StudentFollowupRepositoryHttp implements StudentFollowupRepository {
  final ApiClient _apiClient;

  StudentFollowupRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<StudentFollowup>>> getFollowups({String? status, String? faculty, String? search, int? limit}) async {
    try {
      final followups = await _apiClient.get<List<StudentFollowup>>(
        '/admin/student-followups',
        queryParameters: {
          if (status != null) 'status': status,
          if (faculty != null) 'faculty': faculty,
          if (search != null) 'search': search,
          if (limit != null) 'limit': limit,
        },
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => StudentFollowup.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(followups);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<StudentFollowup>> createFollowup({
    required String studentName,
    required String faculty,
    required String email,
    required String contactNumber,
    required String address,
    required String followUpNote,
    String? visitDate,
    String? status,
  }) async {
    try {
      final created = await _apiClient.post<StudentFollowup>(
        '/admin/student-followups',
        data: {
          'studentName': studentName,
          'faculty': faculty,
          'email': email,
          'contactNumber': contactNumber,
          'address': address,
          'followUpNote': followUpNote,
          if (visitDate != null) 'visitDate': visitDate,
          if (status != null) 'status': status,
        },
        parse: (data) => StudentFollowup.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<StudentFollowup>> updateFollowup({
    required String id,
    String? studentName,
    String? faculty,
    String? email,
    String? contactNumber,
    String? address,
    String? followUpNote,
    String? visitDate,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<StudentFollowup>(
        '/admin/student-followups/$id',
        data: {
          if (studentName != null) 'studentName': studentName,
          if (faculty != null) 'faculty': faculty,
          if (email != null) 'email': email,
          if (contactNumber != null) 'contactNumber': contactNumber,
          if (address != null) 'address': address,
          if (followUpNote != null) 'followUpNote': followUpNote,
          if (visitDate != null) 'visitDate': visitDate,
          if (status != null) 'status': status,
        },
        parse: (data) => StudentFollowup.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteFollowup(String id) async {
    try {
      await _apiClient.delete<void>('/admin/student-followups/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Uint8List>> exportFollowups({String? status, String? faculty, String? search}) async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/admin/student-followups/export',
        queryParameters: {
          if (status != null) 'status': status,
          if (faculty != null) 'faculty': faculty,
          if (search != null) 'search': search,
        },
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
