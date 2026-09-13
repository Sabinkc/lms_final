import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/dashboard/role_dashboard_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/quick_action_card.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The catch-all destination list for whatever isn't a bottom-nav tab —
/// the modernized, exhaustive replacement for the old dashboards' flat
/// `FilledButton` wall. `RoleDashboardConfig.moreItems` is deliberately
/// exhaustive (everything the old dashboard linked to that isn't now a
/// nav tab), so nothing that used to be reachable becomes unreachable.
///
/// Presentation only groups these into titled sections (matching the
/// reference design's "System Management / Communication / ..." boxed
/// groups) — the grouping below is a purely cosmetic re-chunking of
/// `config.moreItems`'s own labels, not a change to `RoleDashboardConfig`'s
/// shape. Any item whose label isn't listed in a group below still renders,
/// under a trailing "Other" group, so a future addition to `moreItems`
/// never silently disappears just because this grouping map wasn't updated.
class MoreScreen extends StatelessWidget {
  final AppRole role;

  const MoreScreen({super.key, required this.role});

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

  @override
  Widget build(BuildContext context) {
    final config = RoleDashboardConfig.forRole(role);
    final accent = AppColors.roleColor(role);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: grouped.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final (title, items) = grouped[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
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
                        color: accent,
                        onTap: () => context.push(items[i].route),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
