import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/app_notification.dart';
import 'notification_repository.dart';

class NotificationRepositoryHttp implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryHttp(this._apiClient);

  @override
  Future<Result<(int, List<AppNotification>)>> getNotifications({int? limit, bool unreadOnly = false}) async {
    try {
      final result = await _apiClient.get<(int, List<AppNotification>)>(
        '/notifications',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (unreadOnly) 'unreadOnly': 'true',
        },
        parse: (data) {
          final map = data as Map<String, dynamic>;
          final unreadCount = (map['unreadCount'] as num?)?.toInt() ?? 0;
          final notifications =
              (map['data'] as List).map((json) => AppNotification.fromJson(json as Map<String, dynamic>)).toList();
          return (unreadCount, notifications);
        },
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> markRead(String id) async {
    try {
      await _apiClient.patch<void>('/notifications/$id/read');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    try {
      await _apiClient.patch<void>('/notifications/read-all');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
