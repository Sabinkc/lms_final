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
import '../../../../shared/widgets/photo_hero_banner.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../exams/presentation/providers/exam_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../timetable/data/models/timetable_day.dart' show timetableWeekdays;
import '../../../timetable/presentation/providers/teacher_timetable_provider.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

/// Teacher Home dashboard — matches [AdminHomeScreen]'s photo-hero restyle.
///
/// "Today's Overview" is deliberately just 3 cards, not 4 — Teacher has no
/// Admin-style aggregate-stats endpoint, and unlike Student/Parent (who have
/// a real attendance-percentage + fees pair to show), the only two
/// standalone, no-extra-plumbing numbers available are "My Sections"
/// ([AttendanceProvider.sections], already loaded for Mark Attendance) and
/// "Today's Periods" (filtered client-side from [TeacherTimetableProvider
/// .entries], which has no server-side "today" filter) — see the research
/// this screen was built from: a Teacher "pending grading" count would need
/// an extra per-assignment round trip this pass didn't add. Upcoming Exams
/// reuses the same shared Exams list Teacher already sees via `/exams/my`.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    final attendance = context.read<AttendanceProvider>();
    final timetable = context.read<TeacherTimetableProvider>();
    final exams = context.read<ExamProvider>();
    final notifications = context.read<NotificationProvider>();
    Future.microtask(() {
      attendance.loadMySections();
      timetable.loadMySchedule();
      exams.loadMyExams();
      notifications.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false) ? user!.fullName.trim().split(' ').first : 'Teacher';
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandHomeAppBar(
          initials: initialsFor(user?.fullName ?? ''),
          unreadCount: unreadCount,
          moreRoute: AppRoutes.teacherMore,
        ),
        body: SingleChildScrollView(
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
                    '${_TeacherQuickTile.all.length} shortcuts',
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
                  for (final tile in _TeacherQuickTile.all)
                    ColorfulActionTile(
                      icon: tile.icon,
                      label: tile.label,
                      color: tile.color,
                      onTap: () => context.push(tile.route),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                "Today's Overview",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _TodaysOverview(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherQuickTile {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _TeacherQuickTile({required this.icon, required this.label, required this.route, required this.color});

  static const all = [
    _TeacherQuickTile(
      icon: Icons.event_available_rounded,
      label: 'Mark Attendance',
      route: AppRoutes.teacherMarkAttendance,
      color: Color(0xFF7C3AED),
    ),
    _TeacherQuickTile(
      icon: Icons.calendar_month_rounded,
      label: 'My Timetable',
      route: AppRoutes.teacherTimetable,
      color: Color(0xFF2563EB),
    ),
    _TeacherQuickTile(icon: Icons.chat_bubble_rounded, label: 'Chat', route: AppRoutes.chat, color: Color(0xFF0D9488)),
    _TeacherQuickTile(
      icon: Icons.assignment_rounded,
      label: 'Assignments',
      route: AppRoutes.assignments,
      color: Color(0xFF4F46E5),
    ),
    _TeacherQuickTile(
      icon: Icons.history_rounded,
      label: 'Attendance History',
      route: AppRoutes.teacherAttendanceHistory,
      color: Color(0xFF0891B2),
    ),
    _TeacherQuickTile(
      icon: Icons.campaign_rounded,
      label: 'Notices',
      route: AppRoutes.notices,
      color: Color(0xFFD97706),
    ),
    _TeacherQuickTile(icon: Icons.quiz_rounded, label: 'Exams', route: AppRoutes.exams, color: Color(0xFF059669)),
    _TeacherQuickTile(
      icon: Icons.account_balance_wallet_rounded,
      label: 'My Payslips',
      route: AppRoutes.teacherPayroll,
      color: Color(0xFF9333EA),
    ),
    _TeacherQuickTile(
      icon: Icons.grid_view_rounded,
      label: 'More',
      route: AppRoutes.teacherMore,
      color: Color(0xFF0B6E4F),
    ),
  ];
}

/// Real data only — see the class doc comment on [TeacherHomeScreen].
class _TodaysOverview extends StatelessWidget {
  const _TodaysOverview();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final timetable = context.watch<TeacherTimetableProvider>();
    final exams = context.watch<ExamProvider>();

    final loading =
        attendance.sectionsStatus == LoadStatus.loading ||
        timetable.status == LoadStatus.loading ||
        exams.status == LoadStatus.loading;
    final hasAnyData = attendance.sections.isNotEmpty || timetable.entries.isNotEmpty || exams.exams.isNotEmpty;

    if (loading && !hasAnyData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final todayName = _todayWeekdayName();
    final todaysPeriods = todayName == null
        ? 0
        : timetable.entries.where((e) => e.day == todayName).fold<int>(0, (sum, e) => sum + e.periods.length);

    final upcomingExams = exams.exams.where((e) => e.status == 'upcoming').toList();
    final nextExam = upcomingExams.isNotEmpty ? upcomingExams.first : null;

    return StatCardRow(
      cards: [
        StatCard(
          icon: Icons.groups_rounded,
          value: '${attendance.sections.length}',
          label: 'My Sections',
          color: const Color(0xFF2563EB),
        ),
        StatCard(
          icon: Icons.today_rounded,
          value: '$todaysPeriods',
          label: 'Periods Today',
          color: const Color(0xFF7C3AED),
        ),
        StatCard(
          icon: Icons.quiz_rounded,
          value: '${upcomingExams.length}',
          label: 'Upcoming Exams',
          color: const Color(0xFF059669),
          trend: nextExam != null ? 'Next: ${nextExam.title}' : null,
        ),
      ],
    );
  }

  /// `timetableWeekdays` is Monday–Saturday only (no Sunday entry exists in
  /// the schema) — `null` on a Sunday means "no periods", not an error.
  static String? _todayWeekdayName() {
    final weekday = DateTime.now().weekday; // 1=Monday..7=Sunday
    if (weekday < 1 || weekday > 6) return null;
    return timetableWeekdays[weekday - 1];
  }
}
