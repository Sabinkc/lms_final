import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/notice.dart';
import 'notice_repository.dart';

class NoticeRepositoryHttp implements NoticeRepository {
  final ApiClient _apiClient;

  NoticeRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Notice>>> getNoticesAsAdmin({String? audience}) async {
    try {
      final notices = await _apiClient.get<List<Notice>>(
        '/notices',
        queryParameters: {if (audience != null) 'audience': audience},
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Notice.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(notices);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Notice>>> getMyNotices() async {
    try {
      final notices = await _apiClient.get<List<Notice>>(
        '/notices/my',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Notice.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(notices);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Notice>> getNoticeById(String id) async {
    try {
      final notice = await _apiClient.get<Notice>(
        '/notices/$id',
        parse: (data) => Notice.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(notice);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Notice>> createNotice({
    required String title,
    required String description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  }) async {
    try {
      final created = await _apiClient.post<Notice>(
        '/notices',
        data: {
          'title': title,
          'description': description,
          if (audience != null) 'audience': audience,
          if (isImportant != null) 'isImportant': isImportant,
          if (expiryDate != null) 'expiryDate': expiryDate,
        },
        parse: (data) => Notice.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(created);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Notice>> updateNotice({
    required String id,
    String? title,
    String? description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  }) async {
    try {
      final updated = await _apiClient.put<Notice>(
        '/notices/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (audience != null) 'audience': audience,
          if (isImportant != null) 'isImportant': isImportant,
          if (expiryDate != null) 'expiryDate': expiryDate,
        },
        parse: (data) => Notice.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteNotice(String id) async {
    try {
      await _apiClient.delete<void>('/notices/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
