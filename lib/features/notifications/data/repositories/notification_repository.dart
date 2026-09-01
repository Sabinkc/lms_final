import '../../../../core/error/result.dart';
import '../models/app_notification.dart';

/// `/api/notifications` — poll/pull only, confirmed by reading
/// `notificationController.js` directly: no real-time channel exists for
/// notifications (Chat's Socket.IO namespace is the only one in this
/// backend, `api_spec.md` §8/§9) — refresh on screen open / pull-to-refresh,
/// never a live subscription.
abstract class NotificationRepository {
  /// `(unreadCount, notifications)` — `GET /` returns both in one call
  /// rather than a separate count endpoint.
  Future<Result<(int, List<AppNotification>)>> getNotifications({int? limit, bool unreadOnly = false});

  Future<Result<void>> markRead(String id);

  Future<Result<void>> markAllRead();
}
