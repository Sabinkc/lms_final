import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/academic_class.dart';
import 'class_repository.dart';

class ClassRepositoryHttp implements ClassRepository {
  final ApiClient _apiClient;

  ClassRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<AcademicClass>>> getClasses() async {
    try {
      final classes = await _apiClient.get<List<AcademicClass>>(
        '/classes',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => AcademicClass.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(classes);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AcademicClass>> createClass({required String name, String? description}) async {
    try {
      final created = await _apiClient.post<AcademicClass>(
        '/classes',
        data: {'name': name, if (description != null) 'description': description},
        parse: (data) => AcademicClass.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AcademicClass>> updateClass({
    required String id,
    String? name,
    String? description,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<AcademicClass>(
        '/classes/$id',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
        },
        parse: (data) => AcademicClass.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteClass(String id) async {
    try {
      await _apiClient.delete<void>('/classes/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
