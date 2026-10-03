import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<AppNotification> _notifications = const [];
  int _unreadCount = 0;
  AppException? _error;

  LoadStatus get status => _status;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  AppException? get error => _error;

  Future<void> loadNotifications({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    // The server returns only 20 by default, fewer than the unread count it reports.
    final result = await _repository.getNotifications(limit: 100);
    result.when(
      success: (data) {
        final (unreadCount, notifications) = data;
        _unreadCount = unreadCount;
        _notifications = notifications;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  /// Optimistic: flips the local flag immediately (tapping a notification
  /// shouldn't wait on a round trip before navigating), then fires the
  /// request — a failure here is silent by design, matching how minor a
  /// missed read-receipt is compared to the navigation the tap triggers.
  Future<void> markRead(String id) async {
    final target = _notifications.where((n) => n.id == id);
    if (target.isEmpty || target.first.isRead) return;

    _notifications = [
      for (final n in _notifications)
        if (n.id == id)
          AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            refId: n.refId,
            refModel: n.refModel,
            createdAt: n.createdAt,
          )
        else
          n,
    ];
    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    notifyListeners();

    await _repository.markRead(id);
  }

  Future<void> markAllRead() async {
    _notifications = [
      for (final n in _notifications)
        AppNotification(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          refId: n.refId,
          refModel: n.refModel,
          createdAt: n.createdAt,
        ),
    ];
    _unreadCount = 0;
    notifyListeners();

    await _repository.markAllRead();
  }
}
