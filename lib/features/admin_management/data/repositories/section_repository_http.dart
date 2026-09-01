import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/class_section.dart';
import 'section_repository.dart';

class SectionRepositoryHttp implements SectionRepository {
  final ApiClient _apiClient;

  SectionRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<ClassSection>>> getSections(String classId) async {
    try {
      final sections = await _apiClient.get<List<ClassSection>>(
        '/classes/$classId/sections',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => ClassSection.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(sections);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ClassSection>> createSection({required String classId, required String name}) async {
    try {
      final created = await _apiClient.post<ClassSection>(
        '/classes/$classId/sections',
        data: {'name': name},
        parse: (data) => ClassSection.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<ClassSection>> updateSection({
    required String id,
    String? name,
    String? classId,
    String? status,
  }) async {
    try {
      final updated = await _apiClient.put<ClassSection>(
        '/sections/$id',
        data: {
          if (name != null) 'name': name,
          if (classId != null) 'classId': classId,
          if (status != null) 'status': status,
        },
        parse: (data) => ClassSection.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteSection(String id) async {
    try {
      await _apiClient.delete<void>('/sections/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
