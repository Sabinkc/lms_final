import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/app_notification.dart';
import '../notification_route.dart';
import '../providers/notification_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

enum _NotificationFilter { all, unread }

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
  _NotificationFilter _filter = _NotificationFilter.all;

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
    final visible = _filter == _NotificationFilter.unread
        ? provider.notifications.where((n) => !n.isRead).toList()
        : provider.notifications;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          showNotifications: false,
          title: provider.unreadCount > 0 ? 'Notifications (${provider.unreadCount})' : 'Notifications',
          actions: [
            if (provider.notifications.any((n) => !n.isRead))
              TextButton.icon(
                onPressed: () => provider.markAllRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
              ),
          ],
        ),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notifications...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadNotifications()),
          LoadStatus.success =>
            provider.notifications.isEmpty
                ? const EmptyStateView(message: 'No notifications yet', icon: Icons.notifications_none)
                : RefreshIndicator(
                    onRefresh: provider.loadNotifications,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppFilterChipBar<_NotificationFilter>(
                          options: _NotificationFilter.values,
                          selected: _filter,
                          onSelected: (value) => setState(() => _filter = value),
                          labelBuilder: (option) => option == _NotificationFilter.all ? 'All' : 'Unread',
                          countBuilder: (option) => option == _NotificationFilter.all
                              ? provider.notifications.length
                              : provider.notifications.where((n) => !n.isRead).length,
                        ),
                        const SizedBox(height: 12),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Center(child: Text('No unread notifications')),
                          )
                        else
                          for (final notification in visible) ...[
                            _NotificationTile(
                              notification: notification,
                              onTap: () {
                                provider.markRead(notification.id);
                                final route = routeForNotification(notification, role);
                                if (route != null) context.push(route);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                      ],
                    ),
                  ),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _typeIcon => switch (notification.type) {
    'fee' => Icons.payments_outlined,
    'attendance' ||
    'attendanceSession' ||
    'attendanceRecord' ||
    'attendanceCorrection' => Icons.event_available_outlined,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: tint.withValues(alpha: 0.14),
                child: Icon(_typeIcon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                          ),
                        ),
                        Text(_relativeTime(notification.createdAt), style: Theme.of(context).textTheme.labelSmall),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Short relative timestamp for a notification card (e.g. "15m ago",
/// "3h ago", "2d ago"), falling back to a plain date beyond a week — purely
/// a presentation nicety over the real `createdAt` field, no new data.
String _relativeTime(String createdAt) {
  final date = DateTime.tryParse(createdAt);
  if (date == null) return createdAt;
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}
