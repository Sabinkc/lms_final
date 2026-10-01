import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/timetable_day.dart';
import '../../data/models/timetable_period.dart';
import '../../../../core/theme/readable_color.dart';

/// Today's weekday name in the backend's `timetableWeekdays` spelling, or
/// null on Sunday (no school day in the 6-day schema).
String? currentWeekday([DateTime? now]) {
  final weekday = (now ?? DateTime.now()).weekday; // 1 = Monday … 7 = Sunday
  return weekday <= timetableWeekdays.length ? timetableWeekdays[weekday - 1] : null;
}

/// Minutes since midnight for the free-text period times the backend
/// stores ("10:00 AM", "9:05 am", "14:30"), or null if unparseable.
int? parsePeriodTime(String raw) {
  final match = RegExp(r'^\s*(\d{1,2})[:.](\d{2})\s*([AaPp][Mm])?\s*$').firstMatch(raw);
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem == 'pm' && hour < 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

enum PeriodState { done, now, next, upcoming }

/// Live state of each period when [isToday]; everything is `upcoming`
/// otherwise (or when times can't be parsed).
List<PeriodState> periodStates(List<TimetablePeriod> periods, {required bool isToday, DateTime? now}) {
  if (!isToday) return [for (final _ in periods) PeriodState.upcoming];
  final t = now ?? DateTime.now();
  final minutes = t.hour * 60 + t.minute;
  var nextAssigned = false;
  return [
    for (final p in periods)
      () {
        final start = parsePeriodTime(p.startTime);
        final end = parsePeriodTime(p.endTime);
        if (start == null || end == null) return PeriodState.upcoming;
        if (minutes >= end) return PeriodState.done;
        if (minutes >= start) return PeriodState.now;
        if (!nextAssigned) {
          nextAssigned = true;
          return PeriodState.next;
        }
        return PeriodState.upcoming;
      }(),
  ];
}

/// Horizontal Mon–Sat pill strip; the selected day is filled green, today
/// is marked with a dot and "TODAY", days with no periods are dimmed.
class DayStrip extends StatelessWidget {
  final List<String> days;
  final String selected;
  final String? today;
  final int Function(String day) periodCount;
  final ValueChanged<String> onSelected;

  const DayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.today,
    required this.periodCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selected;
          final isToday = day == today;
          final count = periodCount(day);
          final fg = isSelected ? Colors.white : (count == 0 ? theme.colorScheme.outline : theme.colorScheme.onSurface);
          return Material(
            color: isSelected ? AppColors.primary : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: () => onSelected(day),
              child: Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.substring(0, 3).toUpperCase(),
                      style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13, height: 1.15),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$count',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20, height: 1.15),
                    ),
                    Text(
                      isToday ? 'TODAY' : (count == 1 ? 'period' : 'periods'),
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One timeline entry: a period plus an optional extra meta line (the
/// class/section for a teacher's merged day).
typedef TimelinePeriod = ({TimetablePeriod period, String? context});

/// Vertical rail timeline of a day's periods, each card showing period
/// number, time range, subject, teacher/room (or class) and its live state.
class PeriodTimeline extends StatelessWidget {
  final List<TimelinePeriod> periods;
  final bool isToday;

  const PeriodTimeline({super.key, required this.periods, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final states = periodStates([for (final p in periods) p.period], isToday: isToday);
    return Column(
      children: [
        for (var i = 0; i < periods.length; i++)
          _TimelineRow(entry: periods[i], state: states[i], isFirst: i == 0, isLast: i == periods.length - 1),
      ],
    );
  }
}

({String label, Color color, IconData icon}) _stateStyle(PeriodState state) => switch (state) {
  PeriodState.done => (label: 'Completed', color: const Color(0xFF64748B), icon: Icons.check_rounded),
  PeriodState.now => (label: 'In Progress', color: AppColors.info, icon: Icons.play_arrow_rounded),
  PeriodState.next => (label: 'Next', color: AppColors.primary, icon: Icons.schedule_rounded),
  PeriodState.upcoming => (label: 'Upcoming', color: const Color(0xFF94A3B8), icon: Icons.circle_outlined),
};

class _TimelineRow extends StatelessWidget {
  final TimelinePeriod entry;
  final PeriodState state;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({required this.entry, required this.state, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _stateStyle(state);
    final period = entry.period;
    final active = state == PeriodState.now;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final railColor = theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(width: 2, height: 18, color: isFirst ? Colors.transparent : railColor),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active ? style.color : style.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: active ? Border.all(color: style.color.withValues(alpha: 0.3), width: 4) : null,
                  ),
                  child: Icon(style.icon, size: 15, color: active ? Colors.white : style.color),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : railColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: active ? BorderSide(color: style.color.withValues(alpha: 0.5), width: 1.5) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PERIOD ${period.periodNumber} · ${period.startTime} – ${period.endTime}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: active ? style.color : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (state != PeriodState.upcoming) AppStatusPill(label: style.label, color: style.color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        period.subject,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: state == PeriodState.done ? theme.colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (entry.context != null)
                            _Meta(icon: Icons.class_outlined, text: entry.context!, style: muted),
                          if (period.teacherName != null)
                            _Meta(icon: Icons.person_outline, text: period.teacherName!, style: muted),
                          if (period.room != null && period.room!.isNotEmpty)
                            _Meta(icon: Icons.place_outlined, text: 'Room ${period.room}', style: muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;

  const _Meta({required this.icon, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: style?.color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}

/// "Today's Routine" summary card: period count, the current/next period,
/// and done/total progress.
class RoutineSummaryCard extends StatelessWidget {
  final String title;
  final List<TimetablePeriod> periods;
  final bool isToday;

  const RoutineSummaryCard({super.key, required this.title, required this.periods, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = periodStates(periods, isToday: isToday);
    final done = states.where((s) => s == PeriodState.done).length;
    final nowIndex = states.indexOf(PeriodState.now);
    final nextIndex = states.indexOf(PeriodState.next);
    final String status;
    if (periods.isEmpty) {
      status = 'No periods scheduled';
    } else if (!isToday) {
      status = 'Starts ${periods.first.startTime} · ends ${periods.last.endTime}';
    } else if (nowIndex >= 0) {
      status = 'Now: Period ${periods[nowIndex].periodNumber} · ${periods[nowIndex].subject}';
    } else if (nextIndex >= 0) {
      status = 'Next: ${periods[nextIndex].subject} at ${periods[nextIndex].startTime}';
    } else {
      status = 'All periods done for today';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.view_timeline_outlined, color: context.readable(AppColors.info)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(
                  '${periods.length} period${periods.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.readable(AppColors.info),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isToday && periods.isNotEmpty)
            Column(
              children: [
                Text('PROGRESS', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
                Text(
                  '$done/${periods.length}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
