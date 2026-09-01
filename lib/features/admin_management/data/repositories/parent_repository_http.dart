import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/parent.dart';
import 'parent_repository.dart';

class ParentRepositoryHttp implements ParentRepository {
  final ApiClient _apiClient;

  ParentRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Parent>>> getParents() async {
    try {
      final parents = await _apiClient.get<List<Parent>>(
        '/parents',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Parent.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(parents);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Parent>> createParent({
    required String fullName,
    required String email,
    String? password,
    String? occupation,
    String? address,
    String? phone,
    List<String>? studentIds,
  }) async {
    try {
      final created = await _apiClient.post<Parent>(
        '/parents',
        data: {
          'fullName': fullName,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          if (occupation != null) 'occupation': occupation,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (studentIds != null) 'students': studentIds,
        },
        parse: (data) => Parent.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Parent>> updateParent({
    required String id,
    String? occupation,
    String? address,
    String? phone,
    String? status,
    List<String>? studentIds,
  }) async {
    try {
      final updated = await _apiClient.put<Parent>(
        '/parents/$id',
        data: {
          if (occupation != null) 'occupation': occupation,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (status != null) 'status': status,
          if (studentIds != null) 'students': studentIds,
        },
        parse: (data) => Parent.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteParent(String id) async {
    try {
      await _apiClient.delete<void>('/parents/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
