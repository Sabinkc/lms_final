import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_attendance_history.dart';

/// Shared summary card + record list, used by both the Student "My
/// Attendance" screen and the Parent "Child's Attendance" screen — same
/// `StudentAttendanceHistory` shape either way (docs/production_roadmap.md
/// Phase C — one backend endpoint authorizes both callers).
class AttendanceHistoryBody extends StatelessWidget {
  final LoadStatus status;
  final StudentAttendanceHistory? history;
  final AppException? error;
  final VoidCallback onRetry;

  const AttendanceHistoryBody({
    super.key,
    required this.status,
    required this.history,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading attendance...'),
      LoadStatus.error => ErrorView(error: error!, onRetry: onRetry),
      LoadStatus.success => history == null || history!.records.isEmpty
          ? const EmptyStateView(message: 'No attendance recorded yet', icon: Icons.event_busy_outlined)
          : Column(
              children: [
                _SummaryCard(summary: history!.summary),
                Expanded(
                  child: ListView.builder(
                    itemCount: history!.records.length,
                    itemBuilder: (context, index) {
                      final record = history!.records[index];
                      return ListTile(
                        title: Text('${record.date} — ${record.subject}'),
                        subtitle: Text('${record.className} · ${record.section}'),
                        trailing: Text(record.status),
                      );
                    },
                  ),
                ),
              ],
            ),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final AttendanceHistorySummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${summary.percentage}%', style: Theme.of(context).textTheme.headlineMedium),
            const Text('attendance'),
            const SizedBox(height: 12),
            Text(
              '${summary.present} present · ${summary.absent} absent · ${summary.late} late · '
              '${summary.leave} leave · ${summary.halfDay} half-day (${summary.total} total)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
