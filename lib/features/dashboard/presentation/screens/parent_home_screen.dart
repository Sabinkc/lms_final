import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/open_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/utils/time_of_day_greeting.dart';
import '../../../../shared/widgets/brand_home_app_bar.dart';
import '../../../../shared/widgets/colorful_action_tile.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../attendance/presentation/providers/self_attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../exams/presentation/providers/exam_provider.dart';
import '../../../fees/presentation/providers/self_fee_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/collapsing_hero_header.dart';
import '../providers/shortcut_usage.dart';

/// Parent Home dashboard — matches [AdminHomeScreen]'s photo-hero restyle.
///
/// "Today's Overview" shows the first linked child's real attendance/fees
/// (from the exact same [SelfAttendanceProvider]/[SelfFeeProvider] the
/// Child's Attendance/Fees screens already use — this app shares those
/// providers between Student's own data and Parent's child data) plus
/// upcoming exams. Neither provider holds more than one child's data at a
/// time (see their own `selectChild`), so a Parent with multiple children
/// sees the first one here by convention, same as how [SelfAttendanceProvider
/// .loadChildren] auto-selects a lone child — the child's own name is shown
/// under the section heading whenever there's more than one, so this is
/// never presented as an all-children aggregate it isn't.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  @override
  void initState() {
    super.initState();
    final attendance = context.read<SelfAttendanceProvider>();
    final fees = context.read<SelfFeeProvider>();
    final exams = context.read<ExamProvider>();
    final notifications = context.read<NotificationProvider>();
    Future.microtask(() async {
      exams.loadMyExams();
      notifications.loadNotifications();

      await attendance.loadChildren();
      if (attendance.children.isNotEmpty && attendance.selectedChildId == null) {
        await attendance.selectChild(attendance.children.first.id);
      }

      await fees.loadChildren();
      if (fees.children.isNotEmpty && fees.selectedChildId == null) {
        await fees.selectChild(fees.children.first.id);
      }
    });
  }

  Future<void> _refresh() async {
    final attendance = context.read<SelfAttendanceProvider>();
    final fees = context.read<SelfFeeProvider>();
    Future<void> reloadAttendance() async {
      await attendance.loadChildren(silent: true);
      final childId = attendance.selectedChildId;
      if (childId != null) await attendance.selectChild(childId, silent: true);
    }

    Future<void> reloadFees() async {
      await fees.loadChildren(silent: true);
      final childId = fees.selectedChildId;
      if (childId != null) await fees.selectChild(childId, silent: true);
    }

    await Future.wait([
      context.read<ExamProvider>().loadMyExams(silent: true),
      context.read<NotificationProvider>().loadNotifications(silent: true),
      reloadAttendance(),
      reloadFees(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Most-used shortcuts first; at most {ShortcutUsage.limit} tiles with More last.
    final shortcuts = context.read<ShortcutUsage?>();
    final tiles =
        shortcuts?.pick(
          role: 'parent',
          all: _ParentQuickTile.all,
          idOf: (t) => t.route,
          isMore: (t) => t.label == 'More',
        ) ??
        _ParentQuickTile.all;
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false) ? user!.fullName.trim().split(' ').first : 'Parent';
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandHomeAppBar(initials: initialsFor(user?.fullName ?? ''), unreadCount: unreadCount),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              CollapsingHeroHeader(
                greeting: timeOfDayGreeting(),
                name: firstName,
                subtitle: "Here's what's happening today at your child's school.",
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
                            tiles.length < _ParentQuickTile.all.length ? 'Most used' : '${tiles.length} shortcuts',
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
                          for (final tile in tiles)
                            ColorfulActionTile(
                              icon: tile.icon,
                              label: tile.label,
                              color: tile.color,
                              onTap: () {
                                shortcuts?.record('parent', tile.route);
                                context.openRoute(tile.route);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _OverviewHeading(),
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

class _OverviewHeading extends StatelessWidget {
  const _OverviewHeading();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<SelfAttendanceProvider>();
    final childName = attendance.history?.studentName;
    final showChildName = attendance.children.length > 1 && childName != null && childName.isNotEmpty;

    return Row(
      children: [
        Text("Today's Overview", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (showChildName) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '· $childName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.readable(AppColors.primary)),
          ),
        ],
      ],
    );
  }
}

class _ParentQuickTile {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _ParentQuickTile({required this.icon, required this.label, required this.route, required this.color});

  static const all = [
    _ParentQuickTile(
      icon: Icons.event_available_rounded,
      label: 'Attendance',
      route: AppRoutes.parentChildAttendance,
      color: AppColors.plum,
    ),
    _ParentQuickTile(icon: Icons.payments_rounded, label: 'Fees', route: AppRoutes.parentFees, color: AppColors.danger),
    _ParentQuickTile(
      icon: Icons.event_note_rounded,
      label: 'Dual Calendar',
      route: AppRoutes.parentDualCalendar,
      color: AppColors.info,
    ),
    _ParentQuickTile(
      icon: Icons.assignment_rounded,
      label: 'Assignments',
      route: AppRoutes.assignments,
      color: AppColors.info,
    ),
    _ParentQuickTile(icon: Icons.campaign_rounded, label: 'Notices', route: AppRoutes.notices, color: AppColors.ochre),
    _ParentQuickTile(icon: Icons.quiz_rounded, label: 'Exams', route: AppRoutes.exams, color: AppColors.success),
    _ParentQuickTile(
      icon: Icons.grid_view_rounded,
      label: 'More',
      route: AppRoutes.parentMore,
      color: AppColors.primary,
    ),
  ];
}

/// Real data only, for the first linked child — see the class doc comment
/// on [ParentHomeScreen] for why only one child is shown here.
class _TodaysOverview extends StatelessWidget {
  const _TodaysOverview();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<SelfAttendanceProvider>();
    final fees = context.watch<SelfFeeProvider>();
    final exams = context.watch<ExamProvider>();

    final loading = attendance.childrenStatus == LoadStatus.loading || attendance.historyStatus == LoadStatus.loading;
    final hasAnyData = attendance.history != null || fees.summary != null || exams.exams.isNotEmpty;

    if (loading && !hasAnyData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (attendance.childrenStatus == LoadStatus.success && attendance.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No student is linked to your account yet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final summary = attendance.history?.summary;
    final feesSummary = fees.summary;
    final upcomingExams = exams.exams.where((e) => e.status == 'upcoming').toList();
    final nextExam = upcomingExams.isNotEmpty ? upcomingExams.first : null;
    final pendingFees = feesSummary == null ? 0 : feesSummary.pending + feesSummary.partial;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          icon: Icons.event_available_rounded,
          value: summary == null ? '—' : '${summary.percentage}%',
          label: "Child's Attendance",
          color: AppColors.success,
          progress: summary == null ? null : summary.percentage / 100,
        ),
        StatCard(
          icon: Icons.check_circle_rounded,
          // "Marked Present", not "Present Days" — see StudentHomeScreen's
          // identical card for why (backend counts "late" as fully attended
          // in its percentage formula, so this raw count can read lower
          // than the rate card without actually disagreeing with it).
          value: '${summary?.present ?? 0}',
          label: 'Marked Present',
          color: AppColors.info,
          trend: summary == null ? null : 'of ${summary.total}',
        ),
        StatCard(
          icon: Icons.receipt_long_rounded,
          value: '$pendingFees',
          label: 'Pending Fees',
          color: AppColors.danger,
          trend: pendingFees > 0 ? 'Action needed' : 'All settled',
        ),
        StatCard(
          icon: Icons.quiz_rounded,
          value: '${upcomingExams.length}',
          label: 'Upcoming Exams',
          color: AppColors.plum,
          trend: nextExam != null ? 'Next: ${nextExam.title}' : null,
        ),
      ],
    );
  }
}
