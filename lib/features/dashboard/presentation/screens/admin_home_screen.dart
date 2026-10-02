import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/utils/time_of_day_greeting.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/brand_home_app_bar.dart';
import '../../../../shared/widgets/colorful_action_tile.dart';
import '../../../../shared/widgets/photo_hero_banner.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// Admin-only Home dashboard — restyled 2026-09-28 to match a real-photo
/// reference design the user supplied (`LMS UI/WhatsApp Image ... 3.24.26
/// PM.jpeg`), which itself matches this app's own Stitch "Verdant Scholar"
/// admin-home mockups (`docs/stitch_screens/cloudslms_admin_home_dashboard_1`)
/// almost exactly. Was the first of 4 role-specific Home screens to replace
/// the old shared `RoleHomeScreen` (since removed) — brand app bar/photo
/// hero/colorful tiles are shared with Teacher/Student/Parent Home
/// (`shared/widgets/`), but the
/// live "Today's Overview" stats stay Admin-only: no other role has an
/// equivalent aggregate-stats backend endpoint (see each role's own Home
/// screen file for what real data it uses instead). The bottom nav bar is
/// untouched — still [RoleShell]'s `NavigationBar`.
///
/// "Today's Overview" is wired to real `/admin/dashboard/*` endpoints
/// (confirmed by reading `Dashboardcontroller.js` directly) rather than the
/// reference image's placeholder numbers — this app's established practice
/// is to never invent data a screen doesn't actually have (see
/// `docs/cloudlms-doc-first-methodology`).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    final dashboard = context.read<AdminDashboardProvider>();
    final notifications = context.read<NotificationProvider>();
    Future.microtask(() {
      dashboard.loadOverview();
      notifications.loadNotifications();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AdminDashboardProvider>().loadOverview(silent: true),
      context.read<NotificationProvider>().loadNotifications(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false) ? user!.fullName.trim().split(' ').first : 'Admin';
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandHomeAppBar(
          initials: initialsFor(user?.fullName ?? ''),
          unreadCount: unreadCount,
          moreRoute: AppRoutes.adminMore,
        ),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoHeroBanner(
                  greeting: timeOfDayGreeting(),
                  name: firstName,
                  subtitle: "Here's what's happening today at your school.",
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_AdminQuickTile.all.length} shortcuts',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.readable(AppColors.primary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.78,
                  children: [
                    for (final tile in _AdminQuickTile.all)
                      ColorfulActionTile(
                        icon: tile.icon,
                        label: tile.label,
                        color: tile.color,
                        onTap: () => context.push(tile.route),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Overview",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(onPressed: () => context.push(AppRoutes.adminReports), child: const Text('View All')),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _TodaysOverview(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminQuickTile {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _AdminQuickTile({required this.icon, required this.label, required this.route, required this.color});

  static const all = [
    _AdminQuickTile(
      icon: Icons.groups_rounded,
      label: 'Students',
      route: AppRoutes.adminStudents,
      color: Color(0xFF2563EB),
    ),
    _AdminQuickTile(
      icon: Icons.badge_rounded,
      label: 'Teachers',
      route: AppRoutes.adminTeachers,
      color: Color(0xFFEA580C),
    ),
    _AdminQuickTile(
      icon: Icons.class_rounded,
      label: 'Classes',
      route: AppRoutes.adminClasses,
      color: Color(0xFF16A34A),
    ),
    _AdminQuickTile(
      icon: Icons.event_available_rounded,
      label: 'Attendance',
      route: AppRoutes.adminAttendanceOverview,
      color: Color(0xFF7C3AED),
    ),
    _AdminQuickTile(icon: Icons.quiz_rounded, label: 'Exams', route: AppRoutes.exams, color: Color(0xFF0D9488)),
    _AdminQuickTile(icon: Icons.payments_rounded, label: 'Fees', route: AppRoutes.adminFees, color: Color(0xFFDC2626)),
    _AdminQuickTile(icon: Icons.campaign_rounded, label: 'Notices', route: AppRoutes.notices, color: Color(0xFFD97706)),
    _AdminQuickTile(
      icon: Icons.assignment_rounded,
      label: 'Assignments',
      route: AppRoutes.assignments,
      color: Color(0xFF4F46E5),
    ),
    _AdminQuickTile(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: AppRoutes.adminReports,
      color: Color(0xFF059669),
    ),
    _AdminQuickTile(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Payroll',
      route: AppRoutes.adminPayroll,
      color: Color(0xFF9333EA),
    ),
    _AdminQuickTile(
      icon: Icons.apartment_rounded,
      label: 'Departments',
      route: AppRoutes.adminDepartments,
      color: Color(0xFF0891B2),
    ),
    _AdminQuickTile(icon: Icons.grid_view_rounded, label: 'More', route: AppRoutes.adminMore, color: Color(0xFF0B6E4F)),
  ];
}

/// The 2x2 real-data stat grid — see [AdminDashboardProvider].
class _TodaysOverview extends StatelessWidget {
  const _TodaysOverview();

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<AdminDashboardProvider>();
    final stats = dashboard.stats;
    final exams = dashboard.upcomingExams;

    if (dashboard.statsStatus == LoadStatus.loading && stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboard.statsStatus == LoadStatus.error && stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          dashboard.statsError?.message ?? 'Could not load today\'s overview.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.readable(AppColors.danger)),
        ),
      );
    }

    final nextExam = exams.isNotEmpty ? exams.first : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.groups_rounded,
          value: '${stats?.totalStudents ?? 0}',
          label: 'Total Students',
          color: const Color(0xFF2563EB),
          trend: stats == null
              ? null
              : '${stats.studentsChangePercent >= 0 ? '+' : ''}${stats.studentsChangePercent.toStringAsFixed(0)}%',
        ),
        StatCard(
          icon: Icons.event_available_rounded,
          value: stats == null ? '—' : '${stats.attendanceRatePercent}%',
          label: 'Attendance This Month',
          color: const Color(0xFF16A34A),
          progress: stats == null ? null : stats.attendanceRatePercent / 100,
        ),
        StatCard(
          icon: Icons.receipt_long_rounded,
          value: '${stats?.pendingFeesCount ?? 0}',
          label: 'Pending Fees',
          color: const Color(0xFFDC2626),
          trend: (stats?.pendingFeesCount ?? 0) > 0 ? 'Action needed' : 'All settled',
        ),
        StatCard(
          icon: Icons.quiz_rounded,
          value: '${exams.length}',
          label: 'Upcoming Exams',
          color: const Color(0xFF7C3AED),
          trend: nextExam != null ? 'Next: ${nextExam.subject}' : null,
        ),
      ],
    );
  }
}
