import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/app_role.dart';
import '../models/my_profile.dart';
import '../models/school_info.dart';
import 'profile_repository.dart';

class ProfileRepositoryHttp implements ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepositoryHttp(this._apiClient);

  static String _profilePath(AppRole role) => switch (role) {
    AppRole.admin => '/admin/profile',
    AppRole.teacher => '/teachers/me',
    AppRole.student => '/students/me',
    AppRole.parent => '/parents/me',
  };

  static Map<String, dynamic> _data(dynamic body) => (body as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  @override
  Future<Result<MyProfile>> getMyProfile(AppRole role) async {
    try {
      final profile = await _apiClient.get<MyProfile>(
        _profilePath(role),
        parse: (data) => MyProfile.fromJson(role, _data(data)),
      );
      return Result.success(profile);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> updateMyProfile(
    AppRole role, {
    required String fullName,
    String? email,
    String? phone,
    String? address,
    DateTime? dob,
    String? occupation,
  }) async {
    final path = role == AppRole.teacher ? '/teachers/update-profile' : _profilePath(role);
    final body = <String, dynamic>{
      'fullName': fullName,
      'phone': ?phone,
      if (role == AppRole.admin) 'email': ?email,
      if (role != AppRole.admin) 'address': ?address,
      if (role == AppRole.student && dob != null) 'dob': _isoDate(dob),
      if (role == AppRole.parent) 'occupation': ?occupation,
    };
    try {
      await _apiClient.put<void>(path, data: body, parse: (_) {});
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> changePassword(
    AppRole role, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final path = switch (role) {
      AppRole.admin => '/admin/change-password',
      AppRole.teacher => '/teachers/change-password',
      AppRole.student => '/students/me/password',
      AppRole.parent => '/parents/me/password',
    };
    try {
      await _apiClient.put<void>(
        path,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          // Only the teacher endpoint asks for it; the others ignore it.
          'confirmPassword': newPassword,
        },
        parse: (_) {},
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String>> uploadMyPhoto(
    AppRole role, {
    required String profileId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = role == AppRole.admin ? '/upload/photo/admin/$profileId' : '/upload/my-photo';
    try {
      final url = await _apiClient.post<String>(
        path,
        data: FormData.fromMap({'photo': MultipartFile.fromBytes(bytes, filename: filename)}),
        // Cloudinary upload on the server side can take a while.
        options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
        parse: (data) => (data as Map<String, dynamic>)['photoUrl'] as String,
      );
      return Result.success(url);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<SchoolInfo>> getMySchool() async {
    try {
      final school = await _apiClient.get<SchoolInfo>('/schools/me', parse: (data) => SchoolInfo.fromJson(_data(data)));
      return Result.success(school);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<SchoolInfo>> uploadSchoolLogo({required Uint8List bytes, required String filename}) async {
    try {
      final school = await _apiClient.put<SchoolInfo>(
        '/schools/me/branding',
        data: FormData.fromMap({'logo': MultipartFile.fromBytes(bytes, filename: filename)}),
        options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
        parse: (data) => SchoolInfo.fromJson(_data(data)),
      );
      return Result.success(school);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
