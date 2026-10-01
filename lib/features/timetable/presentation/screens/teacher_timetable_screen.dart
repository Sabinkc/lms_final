import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/teacher_schedule_entry.dart';
import '../../data/models/timetable_day.dart';
import '../providers/teacher_timetable_provider.dart';
import '../widgets/day_timeline.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// Teacher: View Own Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F2) — read-only, one entry per
/// (class, section, day) this teacher has at least one period in.
class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TeacherTimetableProvider>();
    Future.microtask(() => provider.loadMySchedule());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherTimetableProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Timetable'),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading timetable...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMySchedule()),
          LoadStatus.success =>
            provider.entries.isEmpty
                ? const EmptyStateView(message: 'No periods scheduled for you yet', icon: Icons.schedule_outlined)
                : _buildSchedule(context, provider.entries),
        },
      ),
    );
  }

  Widget _buildSchedule(BuildContext context, List<TeacherScheduleEntry> entries) {
    final byDay = <String, List<TimelinePeriod>>{};
    for (final entry in entries) {
      final label = '${entry.className} ${entry.section}';
      byDay.putIfAbsent(entry.day, () => []).addAll([for (final p in entry.periods) (period: p, context: label)]);
    }
    for (final list in byDay.values) {
      list.sort(
        (a, b) => (parsePeriodTime(a.period.startTime) ?? a.period.periodNumber * 60).compareTo(
          parsePeriodTime(b.period.startTime) ?? b.period.periodNumber * 60,
        ),
      );
    }
    // Schema order first; anything unexpected from the backend still shows.
    final days = [
      for (final d in timetableWeekdays)
        if (byDay.containsKey(d)) d,
      for (final d in byDay.keys)
        if (!timetableWeekdays.contains(d)) d,
    ];
    final today = currentWeekday();
    final selected = _selectedDay != null && days.contains(_selectedDay)
        ? _selectedDay!
        : (days.contains(today) ? today! : days.first);
    final periods = byDay[selected]!;
    final isToday = selected == today;
    final classes = {for (final e in entries) '${e.className} ${e.section}'};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DayStrip(
          days: days,
          selected: selected,
          today: today,
          periodCount: (d) => byDay[d]?.length ?? 0,
          onSelected: (d) => setState(() => _selectedDay = d),
        ),
        const SizedBox(height: 14),
        RoutineSummaryCard(
          title: isToday ? 'Today ($selected)' : '$selected Routine',
          periods: [for (final p in periods) p.period],
          isToday: isToday,
        ),
        const SizedBox(height: 10),
        Text(
          'Teaching ${classes.length} class${classes.length == 1 ? '' : 'es'} this week',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        PeriodTimeline(periods: periods, isToday: isToday),
      ],
    );
  }
}
