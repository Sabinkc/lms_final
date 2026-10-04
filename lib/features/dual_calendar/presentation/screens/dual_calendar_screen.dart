import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Parent: Dual AD/BS Calendar (`docs/production_roadmap.md` Phase L7,
/// `implementation_backlog.md` E22) — a genuinely new requirement no prior
/// CloudsLMS doc captured (`docs/frontend_analysis.md` §4), matching the
/// real web app's `DualCalendar` page. Frontend-only: no backend module
/// backs this, so there is no repository/provider, just [nepali_utils]
/// (`^3.0.8`, researched and picked for this feature — pure Dart, no
/// platform code, the most-adopted BS-conversion package on pub.dev).
///
/// Shape decision: rather than a BS-native month grid (which would need its
/// own leap/variable-day-count month logic layered on top of the AD grid),
/// this paginates by the **Gregorian** month — the familiar 7-day grid —
/// and stacks each day's converted BS date underneath its AD number. That
/// still shows both calendars together for every day, without inventing a
/// second grid-layout algorithm for a P3 day-to-day feature.
class DualCalendarScreen extends StatefulWidget {
  /// Testing seam only — production always opens on the current month.
  /// There's no provider/repository here to inject a fake clock through, so
  /// this optional constructor param is the equivalent for a real,
  /// AD/BS-conversion-accuracy test rather than one relying on whatever
  /// month the test happens to run in.
  final DateTime? initialMonth;

  const DualCalendarScreen({super.key, this.initialMonth});

  @override
  State<DualCalendarScreen> createState() => _DualCalendarScreenState();
}

class _DualCalendarScreenState extends State<DualCalendarScreen> {
  late DateTime _displayedMonth;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final start = widget.initialMonth ?? DateTime.now();
    _displayedMonth = DateTime(start.year, start.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
      _selected = null;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final lastOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, daysInMonth);
    final leadingBlanks = firstOfMonth.weekday % 7; // DateTime.weekday: Mon=1..Sun=7; we want Sun=0
    final bsFirst = firstOfMonth.toNepaliDateTime();
    final bsLast = lastOfMonth.toNepaliDateTime();
    final bsRange = bsFirst.month == bsLast.month
        ? bsFirst.format('MMMM yyyy')
        : '${bsFirst.format('MMMM')} – ${bsLast.format('MMMM yyyy')}';
    final bsRangeNepali = bsFirst.month == bsLast.month
        ? NepaliDateFormat('MMMM yyyy', Language.nepali).format(bsFirst)
        : '${NepaliDateFormat('MMMM', Language.nepali).format(bsFirst)} – '
              '${NepaliDateFormat('MMMM yyyy', Language.nepali).format(bsLast)}';
    final selected = _selected;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Dual Calendar'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const AppStatusPill(label: 'AD', color: AppColors.info),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bsRangeNepali,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.readable(_bsAccent),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'BS $bsRange',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                    IconButton.filledTonal(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const AppStatusPill(label: 'AD + BS synchronized', icon: Icons.sync_rounded, color: AppColors.primary),
                const Spacer(),
                TextButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text('Today'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in _weekdayLabels)
                          Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: label == 'Sat' ? theme.colorScheme.error : null,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: leadingBlanks + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) return const SizedBox.shrink();
                        final day = index - leadingBlanks + 1;
                        final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
                        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

                        return _DayCell(
                          date: date,
                          isToday: isToday,
                          isSelected: selected != null && DateUtils.isSameDay(selected, date),
                          onTap: () => setState(() => _selected = date),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Legend(color: AppColors.primary, label: 'Today'),
                        const SizedBox(width: 16),
                        _Legend(color: theme.colorScheme.error, label: 'Saturday (holiday)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (selected != null) ...[const SizedBox(height: 12), _SelectedDayCard(date: selected)],
          ],
        ),
      ),
    );
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

const _bsAccent = AppColors.ochre;

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({required this.date, required this.isToday, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bsLabel = date.toNepaliDateTime().format('MMM d');
    final isSaturday = date.weekday == DateTime.saturday;
    final fg = isToday ? Colors.white : (isSaturday ? theme.colorScheme.error : theme.colorScheme.onSurface);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary
            : isSaturday
            ? theme.colorScheme.error.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isSelected && !isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
        boxShadow: isToday
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                bsLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isToday ? Colors.white70 : context.readable(_bsAccent).withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Full AD and BS (English + Devanagari) rendering of the tapped day.
class _SelectedDayCard extends StatelessWidget {
  final DateTime date;

  const _SelectedDayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bs = date.toNepaliDateTime();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                  Text(
                    NepaliDateFormat('d MMM', Language.nepali).format(bs),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BS ${bs.format('d MMMM yyyy')}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    NepaliDateFormat('EEE, d MMMM yyyy', Language.nepali).format(bs),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.readable(_bsAccent),
                      fontWeight: FontWeight.w600,
                    ),
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
