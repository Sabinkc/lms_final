import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/teacher_schedule_entry.dart';
import '../providers/teacher_timetable_provider.dart';

/// Teacher: View Own Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F2) — read-only, one entry per
/// (class, section, day) this teacher has at least one period in.
class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<TeacherTimetableProvider>();
    Future.microtask(() => provider.loadMySchedule());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherTimetableProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading timetable...'),
        LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMySchedule()),
        LoadStatus.success => provider.entries.isEmpty
            ? const EmptyStateView(message: 'No periods scheduled for you yet', icon: Icons.schedule_outlined)
            : ListView.builder(
                itemCount: provider.entries.length,
                itemBuilder: (context, index) => _EntryCard(entry: provider.entries[index]),
              ),
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  final TeacherScheduleEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.day} · ${entry.className} ${entry.section}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final period in entry.periods)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('Period ${period.periodNumber}: ${period.subject} (${period.startTime}–${period.endTime})'
                    '${period.room != null && period.room!.isNotEmpty ? ' · Room ${period.room}' : ''}'),
              ),
          ],
        ),
      ),
    );
  }
}
