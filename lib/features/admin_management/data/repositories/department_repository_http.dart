import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/department.dart';
import 'department_repository.dart';

class DepartmentRepositoryHttp implements DepartmentRepository {
  final ApiClient _apiClient;

  DepartmentRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Department>>> getDepartments() async {
    try {
      final departments = await _apiClient.get<List<Department>>(
        '/admin/departments',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Department.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(departments);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Department>> createDepartment({
    required String name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
  }) async {
    try {
      final created = await _apiClient.post<Department>(
        '/admin/departments',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (headOfDepartmentId != null) 'headOfDepartmentId': headOfDepartmentId,
          if (classes != null) 'classes': classes,
        },
        parse: (data) => Department.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Department>> updateDepartment({
    required String id,
    String? name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<Department>(
        '/admin/departments/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (headOfDepartmentId != null) 'headOfDepartmentId': headOfDepartmentId,
          if (classes != null) 'classes': classes,
          if (status != null) 'status': status,
        },
        parse: (data) => Department.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteDepartment(String id) async {
    try {
      await _apiClient.delete<void>('/admin/departments/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
