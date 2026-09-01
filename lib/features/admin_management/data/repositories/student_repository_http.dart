import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/bulk_import_result.dart';
import '../models/student.dart';
import 'student_repository.dart';

class StudentRepositoryHttp implements StudentRepository {
  final ApiClient _apiClient;

  StudentRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Student>>> getStudents({String? className, String? section}) async {
    try {
      final students = await _apiClient.get<List<Student>>(
        '/students',
        queryParameters: {
          if (className != null && className.isNotEmpty) 'class': className,
          if (section != null && section.isNotEmpty) 'section': section,
        },
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Student.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(students);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Student>> getMyProfile() async {
    try {
      final student = await _apiClient.get<Student>(
        '/students/me',
        parse: (data) => Student.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(student);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Student>> createStudent({
    required String className,
    required String section,
    String? fullName,
    String? email,
    String? userId,
    String? password,
    String? admissionNumber,
    String? rollNumber,
    String? parentId,
    String? dob,
    String? address,
    String? phone,
  }) async {
    try {
      final created = await _apiClient.post<Student>(
        '/students',
        data: {
          'class': className,
          'section': section,
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
          if (userId != null) 'userId': userId,
          if (password != null && password.isNotEmpty) 'password': password,
          if (admissionNumber != null) 'admissionNumber': admissionNumber,
          if (rollNumber != null) 'rollNumber': rollNumber,
          if (parentId != null) 'parentId': parentId,
          if (dob != null) 'dob': dob,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
        },
        parse: (data) => Student.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Student>> updateStudent({
    required String id,
    String? admissionNumber,
    String? rollNumber,
    String? className,
    String? section,
    String? parentId,
    String? dob,
    String? address,
    String? phone,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<Student>(
        '/students/$id',
        data: {
          if (admissionNumber != null) 'admissionNumber': admissionNumber,
          if (rollNumber != null) 'rollNumber': rollNumber,
          if (className != null) 'class': className,
          if (section != null) 'section': section,
          if (parentId != null) 'parentId': parentId,
          if (dob != null) 'dob': dob,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (status != null) 'status': status,
        },
        parse: (data) => Student.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteStudent(String id) async {
    try {
      await _apiClient.delete<void>('/students/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<BulkImportResult>> bulkImport(Uint8List fileBytes, String filename) async {
    try {
      final result = await _apiClient.post<BulkImportResult>(
        '/students/bulk-import',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(fileBytes, filename: filename),
        }),
        parse: (data) => BulkImportResult.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Uint8List>> downloadImportTemplate() async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/students/bulk-import/template',
        options: Options(responseType: ResponseType.bytes),
        parse: (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
      return Result.success(bytes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Uint8List>> exportStudents({String? className, String? section}) async {
    try {
      final bytes = await _apiClient.get<Uint8List>(
        '/students/export',
        queryParameters: {
          if (className != null && className.isNotEmpty) 'class': className,
          if (section != null && section.isNotEmpty) 'section': section,
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
