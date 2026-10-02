import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/my_timetable.dart';
import '../../data/models/timetable_day.dart';
import '../providers/student_timetable_provider.dart';
import '../widgets/day_timeline.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// Student: View Own Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F2) — today's schedule up top (the
/// backend's own `todaySchedule` shortcut), then the full week below. Never
/// shows an error for "no timetable yet" — [MyTimetable.empty] renders as an
/// empty state instead, matching `getMyTimetable`'s never-404 contract.
class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentTimetableProvider>();
    Future.microtask(() => provider.loadMyTimetable());
  }

  Future<void> _refresh() async {
    await context.read<StudentTimetableProvider>().loadMyTimetable(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentTimetableProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Timetable'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.status) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading timetable...'),
            LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMyTimetable()),
            LoadStatus.success => _buildContent(context, provider.timetable!),
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyTimetable timetable) {
    if (timetable.empty) {
      return const EmptyStateView(message: 'No timetable set up for your class yet', icon: Icons.schedule_outlined);
    }

    final byDay = {for (final d in timetable.fullSchedule) d.day: d.periods};
    byDay[timetable.todaySchedule.day] ??= timetable.todaySchedule.periods;
    final days = [
      for (final d in timetableWeekdays)
        if (byDay.containsKey(d)) d,
    ];
    final selected = _selectedDay != null && days.contains(_selectedDay) ? _selectedDay! : timetable.today;
    final periods = selected == timetable.todaySchedule.day ? timetable.todaySchedule.periods : byDay[selected] ?? [];
    final isToday = selected == timetable.today;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (days.isNotEmpty) ...[
          DayStrip(
            days: days,
            selected: selected,
            today: timetable.today,
            periodCount: (d) =>
                (d == timetable.todaySchedule.day ? timetable.todaySchedule.periods : byDay[d] ?? []).length,
            onSelected: (d) => setState(() => _selectedDay = d),
          ),
          const SizedBox(height: 14),
        ],
        RoutineSummaryCard(
          title: isToday ? 'Today ($selected)' : '$selected Routine',
          periods: periods,
          isToday: isToday,
        ),
        const SizedBox(height: 16),
        if (periods.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyStateView(message: 'No periods on this day', icon: Icons.event_busy_outlined),
          )
        else
          PeriodTimeline(periods: [for (final p in periods) (period: p, context: null)], isToday: isToday),
      ],
    );
  }
}
