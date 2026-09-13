import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/app_notification.dart';
import '../notification_route.dart';
import '../providers/notification_provider.dart';

/// docs/screens.md / `implementation_backlog.md` E11 — one shared screen
/// for all four roles (`GET /api/notifications` is scoped to the caller by
/// `req.user._id` server-side, same reasoning as every other shared-list
/// screen in this app). Poll/pull only — refreshes on open and via
/// pull-to-refresh, never a live subscription (confirmed no Socket.IO
/// channel exists for notifications, `api_spec.md` §8/§9 — Chat's socket
/// namespace is the only real-time channel in this backend).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    Future.microtask(() => provider.loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final role = context.watch<AuthProvider>().role!;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.unreadCount > 0 ? 'Notifications (${provider.unreadCount})' : 'Notifications'),
        actions: [
          if (provider.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notifications...'),
        LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadNotifications()),
        LoadStatus.success => provider.notifications.isEmpty
            ? const EmptyStateView(message: 'No notifications yet', icon: Icons.notifications_none)
            : RefreshIndicator(
                onRefresh: provider.loadNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () {
                        provider.markRead(notification.id);
                        final route = routeForNotification(notification, role);
                        if (route != null) context.push(route);
                      },
                    );
                  },
                ),
              ),
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _typeIcon => switch (notification.type) {
        'fee' => Icons.payments_outlined,
        'attendance' || 'attendanceSession' || 'attendanceRecord' || 'attendanceCorrection' => Icons.event_available_outlined,
        'assignment' => Icons.assignment_outlined,
        'exam' || 'result' => Icons.quiz_outlined,
        'payroll' => Icons.account_balance_wallet_outlined,
        'subscription' => Icons.workspace_premium_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = notification.isRead ? scheme.onSurfaceVariant : scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      color: notification.isRead ? null : scheme.primary.withValues(alpha: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: tint.withValues(alpha: 0.14),
          child: Icon(_typeIcon, color: tint, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}
