import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/teacher.dart';
import 'teacher_repository.dart';

class TeacherRepositoryHttp implements TeacherRepository {
  final ApiClient _apiClient;

  TeacherRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Teacher>>> getTeachers() async {
    try {
      final teachers = await _apiClient.get<List<Teacher>>(
        '/teachers',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Teacher.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(teachers);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Teacher>> createTeacher({
    required String fullName,
    required String email,
    required String employeeId,
    required String department,
    String? password,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
  }) async {
    try {
      final created = await _apiClient.post<Teacher>(
        '/teachers',
        data: {
          'fullName': fullName,
          'email': email,
          'employeeId': employeeId,
          'department': department,
          if (password != null && password.isNotEmpty) 'password': password,
          if (designation != null) 'designation': designation,
          if (qualification != null) 'qualification': qualification,
          if (subjects != null) 'subjects': subjects,
          if (experience != null) 'experience': experience,
          if (salary != null) 'salary': salary,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        },
        parse: (data) => Teacher.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Teacher>> updateTeacher({
    required String id,
    String? employeeId,
    String? department,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<Teacher>(
        '/teachers/$id',
        data: {
          if (employeeId != null) 'employeeId': employeeId,
          if (department != null) 'department': department,
          if (designation != null) 'designation': designation,
          if (qualification != null) 'qualification': qualification,
          if (subjects != null) 'subjects': subjects,
          if (experience != null) 'experience': experience,
          if (salary != null) 'salary': salary,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
          if (status != null) 'status': status,
        },
        parse: (data) => Teacher.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteTeacher(String id) async {
    try {
      await _apiClient.delete<void>('/teachers/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
