import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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

  @override
  void initState() {
    super.initState();
    final start = widget.initialMonth ?? DateTime.now();
    _displayedMonth = DateTime(start.year, start.month);
  }

  void _changeMonth(int delta) {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // DateTime.weekday: Mon=1..Sun=7; we want Sun=0

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Dual Calendar'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                      Column(
                        children: [
                          Text(
                            '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'BS ${firstOfMonth.toNepaliDateTime().format('MMMM yyyy')} onward',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            for (final label in _weekdayLabels)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                          itemCount: leadingBlanks + daysInMonth,
                          itemBuilder: (context, index) {
                            if (index < leadingBlanks) return const SizedBox.shrink();
                            final day = index - leadingBlanks + 1;
                            final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
                            final isToday =
                                date.year == today.year && date.month == today.month && date.day == today.day;

                            return _DayCell(date: date, isToday: isToday);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const _DayCell({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final bsLabel = date.toNepaliDateTime().format('MMM d');

    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: isToday
          ? BoxDecoration(
              color: accent,
              borderRadius: AppRadius.button,
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? Colors.white : null),
          ),
          Text(
            bsLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isToday ? Colors.white70 : null),
          ),
        ],
      ),
    );
  }
}
