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
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/collapsing_hero_header.dart';
import '../../../../shared/widgets/count_up_text.dart';
import '../../data/models/admin_dashboard_overview.dart';

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
          child: CustomScrollView(
            slivers: [
              CollapsingHeroHeader(
                greeting: timeOfDayGreeting(),
                name: firstName,
                subtitle: "Here's what's happening today at your school.",
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Quick Actions',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
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
                          Expanded(
                            child: Text(
                              "Today's Overview",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.adminReports),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _TodaysOverview(),
                    ],
                  ),
                ),
              ),
            ],
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
      color: AppColors.info,
    ),
    _AdminQuickTile(
      icon: Icons.badge_rounded,
      label: 'Teachers',
      route: AppRoutes.adminTeachers,
      color: AppColors.warning,
    ),
    _AdminQuickTile(
      icon: Icons.class_rounded,
      label: 'Classes',
      route: AppRoutes.adminClasses,
      color: AppColors.success,
    ),
    _AdminQuickTile(
      icon: Icons.event_available_rounded,
      label: 'Attendance',
      route: AppRoutes.adminAttendanceOverview,
      color: AppColors.plum,
    ),
    _AdminQuickTile(icon: Icons.quiz_rounded, label: 'Exams', route: AppRoutes.exams, color: AppColors.teal),
    _AdminQuickTile(icon: Icons.payments_rounded, label: 'Fees', route: AppRoutes.adminFees, color: AppColors.danger),
    _AdminQuickTile(icon: Icons.campaign_rounded, label: 'Notices', route: AppRoutes.notices, color: AppColors.ochre),
    _AdminQuickTile(
      icon: Icons.assignment_rounded,
      label: 'Assignments',
      route: AppRoutes.assignments,
      color: AppColors.info,
    ),
    _AdminQuickTile(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: AppRoutes.adminReports,
      color: AppColors.success,
    ),
    _AdminQuickTile(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Payroll',
      route: AppRoutes.adminPayroll,
      color: AppColors.plum,
    ),
    _AdminQuickTile(
      icon: Icons.apartment_rounded,
      label: 'Departments',
      route: AppRoutes.adminDepartments,
      color: AppColors.teal,
    ),
    _AdminQuickTile(icon: Icons.grid_view_rounded, label: 'More', route: AppRoutes.adminMore, color: AppColors.primary),
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

    // Bento: attendance gets the big tile (the number Admin checks most);
    // students, pending fees and exams sit in a compact column beside it.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _AttendanceHeroTile(stats: stats)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _CompactStat(
                  icon: Icons.groups_rounded,
                  value: '${stats?.totalStudents ?? 0}',
                  label: 'Students',
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompactStat(
                  icon: Icons.receipt_long_rounded,
                  value: '${stats?.pendingFeesCount ?? 0}',
                  label: 'Pending fees',
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompactStat(icon: Icons.quiz_rounded, value: '${exams.length}', label: 'Exams', color: AppColors.plum),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHeroTile extends StatelessWidget {
  final AdminDashboardStats? stats;

  const _AttendanceHeroTile({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = stats?.attendanceRatePercent;
    final change = stats?.attendanceChangePercent ?? 0;
    final color = context.readable(AppColors.success);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance this month', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 116,
                height: 116,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (rate ?? 0) / 100),
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value.clamp(0, 1),
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        color: color,
                        backgroundColor: AppColors.success.withValues(alpha: 0.14),
                      ),
                      Center(
                        child: CountUpText(
                          rate == null ? '—' : '$rate%',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Text(
              stats == null ? ' ' : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}% vs last month',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: context.readable(color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountUpText(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
