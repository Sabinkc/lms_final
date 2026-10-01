import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/app_notification.dart';
import '../notification_route.dart';
import '../providers/notification_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

/// Chip filters: everything, unread only, or one notification category.
const _all = 'All';
const _unread = 'Unread';

/// Groups the backend's `type` enum into the few categories a reader scans
/// by (`notificationSchema.js`: fee | attendance | attendance_correction |
/// assignment | general | subscription | payroll, plus exam/result refs).
({String label, IconData icon, Color color}) _category(String type) => switch (type) {
  'assignment' ||
  'exam' ||
  'result' => (label: 'Academic', icon: Icons.school_outlined, color: const Color(0xFF4F46E5)),
  'attendance' ||
  'attendance_correction' ||
  'attendanceSession' ||
  'attendanceRecord' ||
  'attendanceCorrection' => (label: 'Attendance', icon: Icons.event_available_outlined, color: const Color(0xFF0B6E4F)),
  'fee' ||
  'payroll' ||
  'subscription' => (label: 'Finance', icon: Icons.account_balance_wallet_outlined, color: const Color(0xFFEA580C)),
  _ => (label: 'General', icon: Icons.campaign_outlined, color: const Color(0xFF0891B2)),
};

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
  String _filter = _all;

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
    final categoryCounts = <String, int>{};
    for (final n in provider.notifications) {
      final label = _category(n.type).label;
      categoryCounts[label] = (categoryCounts[label] ?? 0) + 1;
    }
    final unreadCount = provider.notifications.where((n) => !n.isRead).length;
    final filters = [_all, _unread, ...categoryCounts.keys];
    final filter = filters.contains(_filter) ? _filter : _all;
    final visible = switch (filter) {
      _all => provider.notifications,
      _unread => provider.notifications.where((n) => !n.isRead).toList(),
      _ => provider.notifications.where((n) => _category(n.type).label == filter).toList(),
    };

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
                        AppFilterChipBar<String>(
                          options: filters,
                          selected: filter,
                          onSelected: (value) => setState(() => _filter = value),
                          labelBuilder: (option) => option,
                          iconBuilder: (option) => switch (option) {
                            _all => null,
                            _unread => Icons.mark_email_unread_outlined,
                            _ =>
                              provider.notifications
                                  .map((n) => _category(n.type))
                                  .firstWhere((c) => c.label == option)
                                  .icon,
                          },
                          countBuilder: (option) => switch (option) {
                            _all => provider.notifications.length,
                            _unread => unreadCount,
                            _ => categoryCounts[option]!,
                          },
                        ),
                        const SizedBox(height: 12),
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: EmptyStateView(
                              message: filter == _unread ? 'No unread notifications' : 'Nothing in $filter',
                              icon: Icons.mark_email_read_outlined,
                            ),
                          )
                        else ...[
                          for (final notification in visible) ...[
                            _NotificationTile(
                              notification: notification,
                              canOpen: routeForNotification(notification, role) != null,
                              onTap: () {
                                provider.markRead(notification.id);
                                final route = routeForNotification(notification, role);
                                if (route != null) context.push(route);
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (unreadCount == 0) const _CaughtUp(),
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
  final bool canOpen;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.canOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _category(notification.type);
    final unread = !notification.isRead;
    final when = formatRelativeTime(notification.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      color: unread ? null : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: unread ? 0.14 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: unread ? category.color : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          when,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppStatusPill(label: category.label, color: category.color),
                        if (canOpen) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Open',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: context.readable(AppColors.primary)),
                        ],
                      ],
                    ),
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

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: context.readable(AppColors.primary)),
              const SizedBox(width: 6),
              Text("You're all caught up", style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
