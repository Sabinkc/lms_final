import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
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

/// Student Home dashboard — matches [AdminHomeScreen]'s photo-hero restyle
/// (shared app bar/hero/tile widgets in `shared/widgets/`) per the user's
/// explicit "similar kind of homescreen UI... in all other roles too" ask.
///
/// "Today's Overview" uses only data this app already fetches elsewhere for
/// this role — [SelfAttendanceProvider.loadOwnHistory] (My Attendance),
/// [SelfFeeProvider.loadOwnFees] (My Fees), and [ExamProvider.loadMyExams]
/// (the same shared Exams list Student already sees) — no new backend
/// endpoint, and nothing invented: a role with no equivalent Admin-style
/// aggregate stats endpoint gets a stat row built from its own real screens'
/// data instead of fabricated numbers.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    final attendance = context.read<SelfAttendanceProvider>();
    final fees = context.read<SelfFeeProvider>();
    final exams = context.read<ExamProvider>();
    final notifications = context.read<NotificationProvider>();
    Future.microtask(() {
      attendance.loadOwnHistory();
      fees.loadOwnFees();
      exams.loadMyExams();
      notifications.loadNotifications();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SelfAttendanceProvider>().loadOwnHistory(silent: true),
      context.read<SelfFeeProvider>().loadOwnFees(silent: true),
      context.read<ExamProvider>().loadMyExams(silent: true),
      context.read<NotificationProvider>().loadNotifications(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false) ? user!.fullName.trim().split(' ').first : 'Student';
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandHomeAppBar(
          initials: initialsFor(user?.fullName ?? ''),
          unreadCount: unreadCount,
          moreRoute: AppRoutes.studentMore,
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
                            '${_StudentQuickTile.all.length} shortcuts',
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
                          for (final tile in _StudentQuickTile.all)
                            ColorfulActionTile(
                              icon: tile.icon,
                              label: tile.label,
                              color: tile.color,
                              onTap: () => context.push(tile.route),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        child: Text(
                          "Today's Overview",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
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

class _StudentQuickTile {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _StudentQuickTile({required this.icon, required this.label, required this.route, required this.color});

  static const all = [
    _StudentQuickTile(
      icon: Icons.event_available_rounded,
      label: 'My Attendance',
      route: AppRoutes.studentMyAttendance,
      color: AppColors.plum,
    ),
    _StudentQuickTile(
      icon: Icons.calendar_month_rounded,
      label: 'My Timetable',
      route: AppRoutes.studentTimetable,
      color: AppColors.info,
    ),
    _StudentQuickTile(icon: Icons.chat_bubble_rounded, label: 'Chat', route: AppRoutes.chat, color: AppColors.teal),
    _StudentQuickTile(
      icon: Icons.assignment_rounded,
      label: 'Assignments',
      route: AppRoutes.assignments,
      color: AppColors.info,
    ),
    _StudentQuickTile(
      icon: Icons.payments_rounded,
      label: 'My Fees',
      route: AppRoutes.studentFees,
      color: AppColors.danger,
    ),
    _StudentQuickTile(
      icon: Icons.credit_card_rounded,
      label: 'My ID Card',
      route: AppRoutes.studentIdCard,
      color: AppColors.teal,
    ),
    _StudentQuickTile(icon: Icons.campaign_rounded, label: 'Notices', route: AppRoutes.notices, color: AppColors.ochre),
    _StudentQuickTile(icon: Icons.quiz_rounded, label: 'Exams', route: AppRoutes.exams, color: AppColors.success),
    _StudentQuickTile(
      icon: Icons.grid_view_rounded,
      label: 'More',
      route: AppRoutes.studentMore,
      color: AppColors.primary,
    ),
  ];
}

/// Real data only — [SelfAttendanceProvider.history]/[SelfFeeProvider.summary]/
/// [ExamProvider.exams], each already loaded by [_StudentHomeScreenState.initState].
class _TodaysOverview extends StatelessWidget {
  const _TodaysOverview();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<SelfAttendanceProvider>();
    final fees = context.watch<SelfFeeProvider>();
    final exams = context.watch<ExamProvider>();

    final loading =
        attendance.historyStatus == LoadStatus.loading ||
        fees.feesStatus == LoadStatus.loading ||
        exams.status == LoadStatus.loading;
    final hasAnyData = attendance.history != null || fees.summary != null || exams.exams.isNotEmpty;

    if (loading && !hasAnyData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
        child: Center(child: CircularProgressIndicator()),
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
          label: 'Attendance Rate',
          color: AppColors.success,
          progress: summary == null ? null : summary.percentage / 100,
        ),
        StatCard(
          icon: Icons.check_circle_rounded,
          // Deliberately "Marked Present", not "Present Days" — the backend's
          // own attendance-percentage formula counts "late" as fully
          // attended (confirmed via a direct API check), so this raw
          // strictly-present count can legitimately read lower than the
          // rate card above for the same period; a "Present Days" label
          // reads as contradicting it, this one doesn't.
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
