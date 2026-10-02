import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/readable_color.dart';
import '../../data/models/student_attendance_history.dart';
import 'attendance_status_style.dart';

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Which status wins when a day has several sessions (one per subject).
const _priority = {'absent': 5, 'late': 4, 'half_day': 3, 'halfDay': 3, 'leave': 2, 'present': 1};

Color _statusColor(String status) => switch (status) {
  'present' => AttendanceColors.present,
  'absent' => AttendanceColors.absent,
  'late' => AttendanceColors.late,
  'leave' => AttendanceColors.leave,
  _ => AttendanceColors.halfDay,
};

DateTime? _day(String raw) {
  final d = DateTime.tryParse(raw)?.toLocal();
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// Attendance rate after each recorded day, oldest first — the series behind
/// the trend line. Late and half-day count as attended (as the backend's
/// own percentage does); absent and leave don't.
List<double> attendanceRateSeries(List<AttendanceRecordDetail> records) {
  final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
  var attended = 0;
  return [
    for (var i = 0; i < sorted.length; i++)
      () {
        if (sorted[i].status != 'absent' && sorted[i].status != 'leave') attended++;
        return attended / (i + 1);
      }(),
  ];
}

/// "Last 5 weeks" calendar: each school day coloured by that day's status
/// (Sunday-first; Saturdays, the day off, are faded). Ends with the week of
/// the most recent record.
class AttendanceHeatmap extends StatelessWidget {
  final List<AttendanceRecordDetail> records;

  const AttendanceHeatmap({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, String>{};
    for (final record in records) {
      final day = _day(record.date);
      if (day == null) continue;
      final current = byDay[day];
      if (current == null || (_priority[record.status] ?? 0) > (_priority[current] ?? 0)) byDay[day] = record.status;
    }
    final latest = byDay.keys.isEmpty ? DateTime.now() : byDay.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    final weekEnd = DateTime(latest.year, latest.month, latest.day + (6 - latest.weekday % 7));
    final days = [for (var k = 34; k >= 0; k--) DateTime(weekEnd.year, weekEnd.month, weekEnd.day - k)];

    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final first = days.first;
    final last = days.last;
    final range = first.month == last.month
        ? '${_monthNames[first.month - 1]} ${first.year}'
        : '${_monthNames[first.month - 1]} – ${_monthNames[last.month - 1]} ${last.year}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: context.readable(AppColors.primary)),
                const SizedBox(width: 10),
                Text('Last 5 weeks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(range, style: muted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Expanded(
                    child: Center(child: Text(d, style: muted)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [for (final day in days) _DayCell(day: day, status: byDay[day])],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final (label, status) in const [
                  ('Present', 'present'),
                  ('Late', 'late'),
                  ('Absent', 'absent'),
                  ('Leave', 'leave'),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 4),
                      Text(label, style: muted),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final String? status;

  const _DayCell({required this.day, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status == null ? null : _statusColor(status!);
    final dayOff = day.weekday == DateTime.saturday;
    final label = day.day == 1 ? '${_monthNames[day.month - 1]} 1' : '${day.day}';
    return Semantics(
      label: '${_monthNames[day.month - 1]} ${day.day}${status == null ? '' : ', $status'}',
      child: Container(
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.85) ?? theme.colorScheme.onSurface.withValues(alpha: dayOff ? 0.02 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color == null
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: dayOff ? 0.5 : 1)
                    : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
