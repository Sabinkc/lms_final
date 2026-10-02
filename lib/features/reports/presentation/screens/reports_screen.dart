import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/format_rs.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pill_tabs.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/academic_report.dart';
import '../../data/models/attendance_report.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/system_report.dart';
import '../providers/reports_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

/// Admin: Reports Dashboard (`docs/production_roadmap.md` Phase J,
/// `implementation_backlog.md` E12) — four tabs, one per confirmed
/// `/api/reports/*` category. No export/print button anywhere in here: none
/// of the four backend handlers support it (`ReportsRepository`'s doc
/// comment), so E12-F2-T2 stays parked rather than built against nothing.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReportsProvider>();
    Future.microtask(() {
      provider.loadAcademic();
      provider.loadFinancial();
      provider.loadAttendance();
      provider.loadSystem();
    });
  }

  static const _tabs = [
    ('Academic', Icons.school_outlined),
    ('Financial', Icons.account_balance_outlined),
    ('Attendance', Icons.fact_check_outlined),
    ('System', Icons.dns_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Reports'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: PillTabs<int>(
                values: const [0, 1, 2, 3],
                labelOf: (i) => _tabs[i].$1,
                iconOf: (i) => _tabs[i].$2,
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _AcademicTab(provider: provider),
                1 => _FinancialTab(provider: provider),
                2 => _AttendanceTab(provider: provider),
                _ => _SystemTab(provider: provider),
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _green = AppColors.success;
const _orange = AppColors.warning;
const _amber = AppColors.ochre;
const _teal = AppColors.teal;
const _purple = AppColors.plum;

/// Green ≥ 85%, amber ≥ 70%, red below — the same thresholds the
/// attendance overview flags on.
Color _rateColor(double fraction) => fraction >= 0.85 ? _green : (fraction >= 0.7 ? _amber : AppColors.danger);

/// White KPI card: tinted icon, label, big value, optional caption and
/// progress. Two per row in a [_KpiGrid].
class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color color;
  final double? progress;

  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color = AppColors.primary,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: context.readable(color), size: 20),
            ),
            const SizedBox(height: 10),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (caption != null)
              Text(
                caption!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.readable(color),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl4),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lays tiles out two per row with equal heights.
class _KpiGrid extends StatelessWidget {
  final List<Widget> tiles;

  const _KpiGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 10),
                Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One labeled bar in a breakdown: label, count/percent on the right, and a
/// thick rounded bar proportional to [count] out of [total].
class _BreakdownBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color? color;
  final bool showPercent;

  const _BreakdownBar({
    required this.label,
    required this.count,
    required this.total,
    this.color,
    this.showPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;
    final barColor = color ?? _rateColor(fraction);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                showPercent ? '${(fraction * 100).toStringAsFixed(1)}%' : '$count',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.readable(barColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

Color _gradeColor(String grade) {
  final g = grade.toUpperCase();
  if (g.startsWith('A')) return _green;
  if (g.startsWith('B')) return _teal;
  if (g.startsWith('C')) return _amber;
  if (g.startsWith('D')) return _orange;
  return AppColors.danger;
}

Widget _emptyNote(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  ),
);

class _AcademicTab extends StatelessWidget {
  final ReportsProvider provider;

  const _AcademicTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.academicStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading academic report...'),
      LoadStatus.error => ErrorView(error: provider.academicError!, onRetry: () => provider.loadAcademic()),
      LoadStatus.success => _AcademicBody(report: provider.academic!, onRefresh: provider.loadAcademic),
    };
  }
}

class _AcademicBody extends StatelessWidget {
  final AcademicReport report;
  final Future<void> Function() onRefresh;

  const _AcademicBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final gradeTotal = report.gradeDistribution.values.fold(0, (a, b) => a + b);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _KpiGrid(
            tiles: [
              _KpiTile(
                icon: Icons.quiz_outlined,
                label: 'Total Exams',
                value: '${report.totalExams}',
                caption: '${report.upcoming + report.ongoing} upcoming',
                color: AppColors.info,
              ),
              _KpiTile(
                icon: Icons.verified_outlined,
                label: 'Published Results',
                value: '${report.published}',
                caption: '${report.completed} completed',
                color: _green,
              ),
              _KpiTile(
                icon: Icons.trending_up_rounded,
                label: 'Pass Rate',
                // No results yet is "no data", not a 0% failure.
                value: report.totalStudentResults == 0 ? '—' : '${report.passRate.toStringAsFixed(1)}%',
                caption: report.totalStudentResults == 0
                    ? 'No results published'
                    : '${report.totalPassed} of ${report.totalStudentResults} results',
                color: report.totalStudentResults == 0 ? AppColors.info : _rateColor(report.passRate / 100),
                progress: report.totalStudentResults == 0 ? null : report.passRate / 100,
              ),
              _KpiTile(
                icon: Icons.groups_outlined,
                label: 'Students · Teachers',
                value: '${report.totalStudents} · ${report.totalTeachers}',
                caption: 'Enrolled · on staff',
                color: _purple,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Grade Distribution',
            trailing: gradeTotal > 0 ? AppStatusPill(label: '$gradeTotal results', color: AppColors.info) : null,
            child: gradeTotal == 0
                ? _emptyNote(context, 'No published exam results yet.')
                : Column(
                    children: [
                      for (final entry in report.gradeDistribution.entries)
                        _BreakdownBar(
                          label: entry.key,
                          count: entry.value,
                          total: gradeTotal,
                          color: _gradeColor(entry.key),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FinancialTab extends StatelessWidget {
  final ReportsProvider provider;

  const _FinancialTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.financialStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading financial report...'),
      LoadStatus.error => ErrorView(error: provider.financialError!, onRetry: () => provider.loadFinancial()),
      LoadStatus.success => _FinancialBody(report: provider.financial!, onRefresh: provider.loadFinancial),
    };
  }
}

class _FinancialBody extends StatelessWidget {
  final FinancialReport report;
  final Future<void> Function() onRefresh;

  const _FinancialBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final feeCountTotal = report.paidCount + report.partialCount + report.pendingCount;
    final collectionRate = report.totalInvoiced <= 0 ? 0.0 : report.totalCollected / report.totalInvoiced;
    final white75 = Colors.white.withValues(alpha: 0.75);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'FEE COLLECTION RATE',
                  style: TextStyle(color: white75, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(collectionRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                Text('of ${formatRs(report.totalInvoiced)} invoiced', style: TextStyle(color: white75)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl4),
                  child: LinearProgressIndicator(
                    value: collectionRate.clamp(0, 1),
                    minHeight: 8,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _KpiGrid(
            tiles: [
              _KpiTile(
                icon: Icons.check_circle_outline,
                label: 'Collected',
                value: formatRs(report.totalCollected),
                color: _green,
              ),
              _KpiTile(
                icon: Icons.schedule_outlined,
                label: 'Pending',
                value: formatRs(report.totalPending),
                color: _orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Fee Status',
            trailing: AppStatusPill(label: '$feeCountTotal fees', color: AppColors.info),
            child: feeCountTotal == 0
                ? _emptyNote(context, 'No fees issued yet.')
                : Column(
                    children: [
                      _BreakdownBar(label: 'Paid', count: report.paidCount, total: feeCountTotal, color: _green),
                      _BreakdownBar(label: 'Partial', count: report.partialCount, total: feeCountTotal, color: _amber),
                      _BreakdownBar(
                        label: 'Pending',
                        count: report.pendingCount,
                        total: feeCountTotal,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payroll',
            child: _KpiGrid(
              tiles: [
                _KpiTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Paid',
                  value: formatRs(report.payrollTotalPaid),
                  color: _green,
                ),
                _KpiTile(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending',
                  value: formatRs(report.payrollTotalPending),
                  color: _orange,
                ),
                _KpiTile(
                  icon: Icons.payments_outlined,
                  label: 'Fee Payments',
                  value: '${report.totalPayments}',
                  caption: 'submitted',
                  color: AppColors.info,
                ),
                _KpiTile(
                  icon: Icons.summarize_outlined,
                  label: 'Net Payroll',
                  value: formatRs(report.payrollTotalNetSalary),
                  color: _purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  final ReportsProvider provider;

  const _AttendanceTab({required this.provider});

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: widget.provider.attendanceStartDate != null && widget.provider.attendanceEndDate != null
          ? DateTimeRange(start: widget.provider.attendanceStartDate!, end: widget.provider.attendanceEndDate!)
          : null,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    widget.provider.loadAttendance(startDate: picked.start, endDate: picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final start = provider.attendanceStartDate;
    final end = provider.attendanceEndDate;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Row(
                children: [
                  Icon(Icons.date_range_outlined, color: context.readable(AppColors.primary), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      start != null && end != null
                          ? '${formatDisplayDate(start.toIso8601String())} – ${formatDisplayDate(end.toIso8601String())}'
                          : 'All time',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(onPressed: () => _pickRange(context), child: const Text('Date range')),
                  if (start != null)
                    IconButton(
                      tooltip: 'Clear filter',
                      icon: const Icon(Icons.clear),
                      onPressed: () => provider.loadAttendance(),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: switch (provider.attendanceStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading attendance report...'),
            LoadStatus.error => ErrorView(
              error: provider.attendanceError!,
              onRetry: () => provider.loadAttendance(startDate: start, endDate: end),
            ),
            LoadStatus.success => _AttendanceBody(
              report: provider.attendance!,
              onRefresh: () => provider.loadAttendance(startDate: start, endDate: end),
            ),
          },
        ),
      ],
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  final AttendanceReport report;
  final Future<void> Function() onRefresh;

  const _AttendanceBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classes = report.classBreakdown.entries.where((e) => e.value.total > 0).toList()
      ..sort((a, b) => (b.value.present / b.value.total).compareTo(a.value.present / a.value.total));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _KpiGrid(
            tiles: [
              _KpiTile(
                icon: Icons.pie_chart_outline,
                label: 'Attendance Rate',
                value: report.total == 0 ? '—' : '${report.attendanceRate.toStringAsFixed(1)}%',
                caption: report.total == 0 ? 'No records in range' : '${report.total} records',
                color: report.total == 0 ? AppColors.info : _rateColor(report.attendanceRate / 100),
                progress: report.total == 0 ? null : report.attendanceRate / 100,
              ),
              _KpiTile(
                icon: Icons.groups_outlined,
                label: 'Students',
                value: '${report.totalStudents}',
                caption: 'in range',
                color: _purple,
              ),
              _KpiTile(icon: Icons.how_to_reg_outlined, label: 'Present', value: '${report.present}', color: _green),
              _KpiTile(
                icon: Icons.person_off_outlined,
                label: 'Absent · Late',
                value: '${report.absent} · ${report.late}',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.leaderboard_outlined,
            title: 'By Class & Section',
            child: classes.isEmpty
                ? _emptyNote(context, 'No attendance records for this range.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in classes)
                        _BreakdownBar(
                          label: entry.key,
                          count: entry.value.present,
                          total: entry.value.total,
                          showPercent: true,
                        ),
                      if (classes.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _Callout(
                                icon: Icons.north_east_rounded,
                                title: 'Highest',
                                value: classes.first.key,
                                color: _green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Callout(
                                icon: Icons.warning_amber_rounded,
                                title: 'Needs focus',
                                value: classes.last.key,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          if (report.classBreakdown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Present share per class; green ≥ 85%, amber ≥ 70%.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _Callout({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 16, color: context.readable(color)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelSmall),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.readable(color),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemTab extends StatelessWidget {
  final ReportsProvider provider;

  const _SystemTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.systemStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading system report...'),
      LoadStatus.error => ErrorView(error: provider.systemError!, onRetry: () => provider.loadSystem()),
      LoadStatus.success => _SystemBody(report: provider.system!, onRefresh: provider.loadSystem),
    };
  }
}

class _SystemBody extends StatelessWidget {
  final SystemReport report;
  final Future<void> Function() onRefresh;

  const _SystemBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionTotal = report.actionBreakdown.values.fold(0, (a, b) => a + b);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _KpiGrid(
            tiles: [
              _KpiTile(
                icon: Icons.groups_outlined,
                label: 'Students',
                value: '${report.totalStudents}',
                color: AppColors.info,
              ),
              _KpiTile(icon: Icons.badge_outlined, label: 'Teachers', value: '${report.totalTeachers}', color: _orange),
              _KpiTile(
                icon: Icons.family_restroom_outlined,
                label: 'Parents',
                value: '${report.totalParents}',
                color: _purple,
              ),
              _KpiTile(icon: Icons.history_rounded, label: 'Audit Entries', value: '${report.totalLogs}', color: _teal),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.category_outlined,
            title: 'Activity by Category',
            child: actionTotal == 0
                ? _emptyNote(context, 'No audit log entries yet.')
                : Column(
                    children: [
                      for (final entry in report.actionBreakdown.entries)
                        _BreakdownBar(label: entry.key, count: entry.value, total: actionTotal, color: AppColors.info),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Recent Activity',
            child: report.recentLogs.isEmpty
                ? const EmptyStateView(message: 'No recent activity', icon: Icons.history)
                : Column(
                    children: [
                      for (final log in report.recentLogs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                                child: Icon(Icons.bolt_rounded, size: 16, color: context.readable(AppColors.info)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.action,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${log.user} · ${log.category}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AppStatusPill(
                                label: log.status,
                                color: log.status.toLowerCase() == 'success' ? _green : AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
