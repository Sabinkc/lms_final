import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/stat_card.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StatCardRow(cards: [
            StatCard(icon: Icons.pie_chart_outline, value: '${summary.percentage}%', label: 'Attendance', color: scheme.primary),
            StatCard(icon: Icons.check_circle_outline, value: '${summary.present}', label: 'Present', color: Colors.green),
            StatCard(icon: Icons.cancel_outlined, value: '${summary.absent}', label: 'Absent', color: scheme.error),
            StatCard(icon: Icons.schedule_outlined, value: '${summary.late}', label: 'Late', color: Colors.orange),
          ]),
          if (summary.leave > 0 || summary.halfDay > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${summary.leave} leave · ${summary.halfDay} half-day · ${summary.total} total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
