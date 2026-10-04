import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/dashboard/role_dashboard_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/brand_home_app_bar.dart';
import '../../../../shared/widgets/quick_action_card.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../core/theme/theme_controller.dart';

/// The catch-all destination list for whatever isn't a bottom-nav tab —
/// the modernized, exhaustive replacement for the old dashboards' flat
/// `FilledButton` wall. `RoleDashboardConfig.moreItems` is deliberately
/// exhaustive (everything the old dashboard linked to that isn't now a
/// nav tab), so nothing that used to be reachable becomes unreachable.
///
/// Restyled 2026-09-29 to match a reference design the user supplied
/// (`LMS UI/WhatsApp Image ... 4.20.11 PM.jpeg`) "where possible": the
/// branded app bar (shared with the 4 Home screens), full-width groups
/// stacked vertically (the reference's paired 2-column groups were dropped
/// 2026-09-30 as too cramped on phones), and icon+title+subtitle rows
/// all map onto this screen's existing data. What doesn't: the reference's
/// "Academic Year"/"Storage Used" stat-strip entries have no backing field
/// anywhere in this app, so the strip below the profile card only shows
/// Admin's real totals (Students/Teachers/Pending Fees, from the same
/// `AdminDashboardProvider` Admin Home already uses) and is omitted
/// entirely for the other 3 roles, which have no equivalent aggregate.
class MoreScreen extends StatefulWidget {
  final AppRole role;

  const MoreScreen({super.key, required this.role});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const Map<AppRole, List<(String title, List<String> labels)>> _groups = {
    AppRole.admin: [
      ('People & Structure', ['Manage Classes', 'Manage Students', 'Manage Teachers', 'Manage Parents', 'Departments']),
      ('Attendance & Schedule', ['Attendance Corrections', 'Timetable']),
      ('Academic', ['Assignments', 'Exams', 'Student Follow-ups']),
      ('Communication', ['Notices']),
      ('Finance', ['Fee Payment Review', 'Payroll']),
      ('Reports & Data', ['Reports', 'Backup & Data', 'ID Cards']),
    ],
    AppRole.teacher: [
      ('Attendance', ['Attendance History']),
      ('Academic', ['Assignments', 'Exams']),
      ('Communication', ['Notices', 'Chat']),
      ('Finance', ['My Payslips']),
    ],
    AppRole.student: [
      ('Academic', ['Assignments', 'Exams']),
      ('Communication', ['Notices', 'Chat']),
      ('Finance', ['My Fees']),
    ],
    AppRole.parent: [
      ('Academic', ['Assignments', 'Exams']),
      ('Communication', ['Notices']),
    ],
  };

  /// Short, real descriptions of each real destination — UI copy, not data.
  static const Map<String, String> _subtitles = {
    'Manage Classes': 'Manage classes and sections',
    'Manage Students': 'Add, edit and view students',
    'Manage Teachers': 'Add, edit and view teachers',
    'Manage Parents': 'Manage linked parent accounts',
    'Departments': 'Manage academic departments',
    'Attendance Corrections': 'Review and approve corrections',
    'Attendance History': 'View your past attendance sessions',
    'Timetable': 'Manage class schedules',
    'Assignments': 'Manage and track assignments',
    'Exams': 'Manage exams and results',
    'Student Follow-ups': 'Track prospective/enrolled visits',
    'Notices': 'Send and read school notices',
    'Chat': 'Message students and teachers',
    'Fee Payment Review': 'Approve pending fee payments',
    'Payroll': 'Manage teacher salaries',
    'My Payslips': 'View your salary history',
    'My Fees': 'View fee status and pay online',
    'Reports': 'View school reports',
    'Backup & Data': 'Download a school data backup',
    'ID Cards': 'Generate student ID cards',
  };

  static String _roleLabel(AppRole role) => switch (role) {
    AppRole.admin => 'Administrator',
    AppRole.teacher => 'Teacher',
    AppRole.student => 'Student',
    AppRole.parent => 'Parent',
  };

  @override
  void initState() {
    super.initState();
    final notifications = context.read<NotificationProvider>();
    final dashboard = widget.role == AppRole.admin ? context.read<AdminDashboardProvider>() : null;
    Future.microtask(() {
      notifications.loadNotifications();
      if (dashboard != null && dashboard.statsStatus == LoadStatus.initial) dashboard.loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final config = RoleDashboardConfig.forRole(role);
    // Matches every role's Home screen: Stitch's own More-screen mockups
    // use the same uniform primary-container green across all 4 roles
    // (checked directly), not a per-role tint.
    final accent = AppColors.primary;
    final user = context.watch<AuthProvider>().user;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final groupDefs = _groups[role] ?? const [];

    final grouped = <(String title, List<QuickAction> items)>[];
    final placed = <String>{};
    for (final (title, labels) in groupDefs) {
      final items = [
        for (final action in config.moreItems)
          if (labels.contains(action.label)) action,
      ];
      if (items.isEmpty) continue;
      grouped.add((title, items));
      placed.addAll(items.map((a) => a.label));
    }
    final leftover = [
      for (final action in config.moreItems)
        if (!placed.contains(action.label)) action,
    ];
    if (leftover.isNotEmpty) grouped.add(('Other', leftover));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandHomeAppBar(initials: initialsFor(user?.fullName ?? ''), unreadCount: unreadCount),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProfileCard(name: user?.fullName, email: user?.email, role: role, accent: accent),
            if (role == AppRole.admin) ...[const SizedBox(height: AppSpacing.md), const _AdminStatStrip()],
            const SizedBox(height: AppSpacing.lg),
            // Every group full-width, stacked vertically — paired 2-column
            // groups were too cramped on phone widths (titles/subtitles
            // truncated), so this deliberately departs from the reference.
            for (var i = 0; i < grouped.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              _GroupSection(title: grouped[i].$1, items: grouped[i].$2, accent: accent),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _AppearanceCard(),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => runWithProgress(context, context.read<AuthProvider>().logout, message: 'Logging out…'),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4)),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final String title;
  final List<QuickAction> items;
  final Color accent;

  const _GroupSection({required this.title, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Icon(Icons.settings_outlined, color: Colors.white, size: 15),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: context.readable(accent), fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                QuickActionTile(
                  icon: items[i].icon,
                  label: items[i].label,
                  subtitle: _MoreScreenState._subtitles[items[i].label],
                  color: accent,
                  onTap: () => context.push(items[i].route),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Real-only aggregate row for Admin — see [MoreScreen]'s class doc comment
/// for why this doesn't appear for the other 3 roles.
class _AdminStatStrip extends StatelessWidget {
  const _AdminStatStrip();

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<AdminDashboardProvider>();
    final stats = dashboard.stats;
    if (stats == null) return const SizedBox.shrink();

    return StatCardRow(
      cards: [
        StatCard(icon: Icons.groups_rounded, value: '${stats.totalStudents}', label: 'Students', color: AppColors.info),
        StatCard(
          icon: Icons.badge_rounded,
          value: '${stats.totalTeachers}',
          label: 'Teachers',
          color: AppColors.warning,
        ),
        StatCard(
          icon: Icons.receipt_long_rounded,
          value: '${stats.pendingFeesCount}',
          label: 'Pending Fees',
          color: AppColors.danger,
        ),
      ],
    );
  }
}

/// Real-data identity header — name/email/role from the signed-in
/// [AppUser], nothing invented (no institution name, no "verified" badge,
/// no ID number like the Stitch mockup shows — this app has no such field
/// on `AppUser` to source them from).
class _ProfileCard extends StatelessWidget {
  final String? name;
  final String? email;
  final AppRole role;
  final Color accent;

  const _ProfileCard({required this.name, required this.email, required this.role, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = (name != null && name!.trim().isNotEmpty) ? name!.trim() : _MoreScreenState._roleLabel(role);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accent,
              child: Text(
                initialsFor(displayName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email != null && email!.isNotEmpty)
                    Text(email!, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: AppRadius.button),
                    child: Text(
                      _MoreScreenState._roleLabel(role),
                      style: textTheme.labelSmall?.copyWith(
                        color: context.readable(accent),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light / Dark / System switch. Applies instantly and is remembered.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ThemeController>();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text('Appearance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System'),
                  ),
                ],
                selected: {controller.mode},
                onSelectionChanged: (s) => controller.setMode(s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
