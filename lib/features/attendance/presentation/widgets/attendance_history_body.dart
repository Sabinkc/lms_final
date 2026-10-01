import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_attendance_history.dart';
import 'attendance_status_style.dart';

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
      LoadStatus.success =>
        history == null || history!.records.isEmpty
            ? const EmptyStateView(message: 'No attendance recorded yet', icon: Icons.event_busy_outlined)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SummaryTiles(summary: history!.summary),
                  const SizedBox(height: AppSpacing.md),
                  _RecordsCard(records: history!.records),
                ],
              ),
    };
  }
}

/// Rate / Present / Absent / Late tiles — the same look as the Attendance
/// tab on Admin's Student Profile.
class _SummaryTiles extends StatelessWidget {
  final AttendanceHistorySummary summary;

  const _SummaryTiles({required this.summary});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: AppSpacing.sm);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.pie_chart_rounded,
                label: 'Rate',
                value: '${summary.percentage}%',
                caption: '${summary.total} ${summary.total == 1 ? 'day' : 'days'}',
                color: AppColors.primary,
              ),
            ),
            gap,
            Expanded(
              child: TintedStatTile(
                icon: Icons.check_circle,
                label: 'Present',
                value: '${summary.present}',
                color: AttendanceColors.present,
              ),
            ),
            gap,
            Expanded(
              child: TintedStatTile(
                icon: Icons.cancel,
                label: 'Absent',
                value: '${summary.absent}',
                color: AttendanceColors.absent,
              ),
            ),
            gap,
            Expanded(
              child: TintedStatTile(
                icon: Icons.schedule,
                label: 'Late',
                value: '${summary.late}',
                color: AttendanceColors.late,
              ),
            ),
          ],
        ),
        if (summary.leave > 0 || summary.halfDay > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('${summary.leave} leave · ${summary.halfDay} half-day', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// One card, "Recent Attendance": date + subject/class on the left, status
/// pill on the right, divider between days.
class _RecordsCard extends StatelessWidget {
  final List<AttendanceRecordDetail> records;

  const _RecordsCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Text('Recent Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < records.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDisplayDate(records[i].date),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              if (records[i].subject.isNotEmpty) records[i].subject,
                              [records[i].className, records[i].section].where((p) => p.isNotEmpty).join(' · '),
                            ].where((p) => p.isNotEmpty).join('  •  '),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    AttendanceStatusPill(status: records[i].status),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
