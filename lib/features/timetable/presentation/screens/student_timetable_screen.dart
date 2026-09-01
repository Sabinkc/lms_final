import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/my_timetable.dart';
import '../../data/models/timetable_period.dart';
import '../providers/student_timetable_provider.dart';

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
  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentTimetableProvider>();
    Future.microtask(() => provider.loadMyTimetable());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentTimetableProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading timetable...'),
        LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMyTimetable()),
        LoadStatus.success => _buildContent(context, provider.timetable!),
      },
    );
  }

  Widget _buildContent(BuildContext context, MyTimetable timetable) {
    if (timetable.empty) {
      return const EmptyStateView(message: 'No timetable set up for your class yet', icon: Icons.schedule_outlined);
    }

    final today = timetable.todaySchedule;
    final fullSchedule = timetable.fullSchedule;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Today (${timetable.today})', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (today.periods.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No periods today'))
        else
          for (final period in today.periods) _PeriodTile(period: period),
        const Divider(height: 32),
        Text('Full Week', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final day in fullSchedule)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(day.day),
              subtitle: Text('${day.periods.length} period(s)'),
              children: [for (final period in day.periods) _PeriodTile(period: period)],
            ),
          ),
      ],
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final TimetablePeriod period;

  const _PeriodTile({required this.period});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text('Period ${period.periodNumber}: ${period.subject}'),
      subtitle: Text(
        '${period.startTime}–${period.endTime}'
        '${period.teacherName != null ? ' · ${period.teacherName}' : ''}'
        '${period.room != null && period.room!.isNotEmpty ? ' · Room ${period.room}' : ''}',
      ),
    );
  }
}
