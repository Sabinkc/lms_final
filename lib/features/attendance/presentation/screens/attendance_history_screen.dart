import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/widgets/class_badge.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_session.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_status_style.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// docs/screens.md "Attendance History" (Teacher, read-only). The backend
/// requires a `date` filter on every read (`studentattendanceController.js`'s
/// `getAttendanceByDate` 400s without one) — this is "what I submitted on
/// this date," not an open-ended scrollable history, so the screen is a
/// date-picker over per-day session summaries rather than an infinite list.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    Future.microtask(() => provider.loadHistory(_formatDate(_date)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    // Date picker lives in the page (not the app bar), where it doesn't
    // squeeze the title — same pill as the Students screen.
    final datePill = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Submitted on',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(formatDisplayDate(_formatDate(_date))),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _date = picked);
                provider.loadHistory(_formatDate(picked));
              }
            },
          ),
        ],
      ),
    );

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrandAppBar(title: 'Attendance History'),
        body: Column(
          children: [
            datePill,
            Expanded(child: _body(provider)),
          ],
        ),
      ),
    );
  }

  Widget _body(AttendanceProvider provider) {
    return switch (provider.historyStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading history...'),
      LoadStatus.error => ErrorView(
        error: provider.historyError!,
        onRetry: () => provider.loadHistory(_formatDate(_date)),
      ),
      LoadStatus.success =>
        provider.historySessions.isEmpty
            ? const EmptyStateView(message: 'No attendance submitted on this date', icon: Icons.event_busy_outlined)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _DaySummaryRow(sessions: provider.historySessions),
                  const SizedBox(height: AppSpacing.md),
                  for (final session in provider.historySessions) ...[
                    _SessionCard(session: session),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
    };
  }
}

class _DaySummaryRow extends StatelessWidget {
  final List<AttendanceSessionSummary> sessions;

  const _DaySummaryRow({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final present = sessions.fold<int>(0, (sum, s) => sum + s.presentCount);
    final absent = sessions.fold<int>(0, (sum, s) => sum + s.absentCount);
    final late = sessions.fold<int>(0, (sum, s) => sum + s.lateCount);
    const gap = SizedBox(width: AppSpacing.sm);

    return Row(
      children: [
        Expanded(
          child: TintedStatTile(
            icon: Icons.class_rounded,
            label: 'Classes',
            value: '${sessions.length}',
            color: AppColors.primary,
          ),
        ),
        gap,
        Expanded(
          child: TintedStatTile(
            icon: Icons.check_circle,
            label: 'Present',
            value: '$present',
            color: AttendanceColors.present,
          ),
        ),
        gap,
        Expanded(
          child: TintedStatTile(icon: Icons.cancel, label: 'Absent', value: '$absent', color: AttendanceColors.absent),
        ),
        gap,
        Expanded(
          child: TintedStatTile(icon: Icons.schedule, label: 'Late', value: '$late', color: AttendanceColors.late),
        ),
      ],
    );
  }
}

/// One class's day: badge + name, subject when known, and coloured counts.
class _SessionCard extends StatelessWidget {
  final AttendanceSessionSummary session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget count(String status, int n) {
      final (label, icon, color) = attendanceStatusStyle(status, theme.colorScheme);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.xl4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$n $label',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassBadge(name: session.className, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (session.locked) Icon(Icons.lock_outline, size: 18, color: muted?.color),
                    ],
                  ),
                  Text(
                    [
                      if (session.subject.isNotEmpty) session.subject,
                      '${session.totalCount} ${session.totalCount == 1 ? 'student' : 'students'}',
                    ].join('  •  '),
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      count('present', session.presentCount),
                      count('absent', session.absentCount),
                      count('late', session.lateCount),
                    ],
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
