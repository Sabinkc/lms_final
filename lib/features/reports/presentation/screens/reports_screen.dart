import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../../data/models/academic_report.dart';
import '../../data/models/attendance_report.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/system_report.dart';
import '../providers/reports_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Academic'),
              Tab(text: 'Financial'),
              Tab(text: 'Attendance'),
              Tab(text: 'System'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AcademicTab(provider: provider),
            _FinancialTab(provider: provider),
            _AttendanceTab(provider: provider),
            _SystemTab(provider: provider),
          ],
        ),
      ),
    );
  }
}

/// A single labeled bar in a breakdown — width proportional to [count] out
/// of [total], no charting package needed for a one-row-per-category list.
class _BreakdownBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;

  const _BreakdownBar({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: fraction, minHeight: 8),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _AcademicTab extends StatelessWidget {
  final ReportsProvider provider;

  const _AcademicTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.academicStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(
        message: 'Loading academic report...',
      ),
      LoadStatus.error => ErrorView(
        error: provider.academicError!,
        onRetry: () => provider.loadAcademic(),
      ),
      LoadStatus.success => _AcademicBody(
        report: provider.academic!,
        onRefresh: provider.loadAcademic,
      ),
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
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.quiz_outlined,
                  value: '${report.totalExams}',
                  label: 'Total exams',
                ),
                StatCard(
                  icon: Icons.check_circle_outline,
                  value: '${report.published}',
                  label: 'Published',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.trending_up_outlined,
                  value: '${report.passRate.toStringAsFixed(1)}%',
                  label: 'Pass rate',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.groups_outlined,
                  value: '${report.totalStudents}',
                  label: 'Students',
                ),
                StatCard(
                  icon: Icons.badge_outlined,
                  value: '${report.totalTeachers}',
                  label: 'Teachers',
                ),
                StatCard(
                  icon: Icons.assignment_turned_in_outlined,
                  value: '${report.totalStudentResults}',
                  label: 'Results recorded',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Grade distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (gradeTotal == 0)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No published exam results yet.'),
            )
          else
            for (final entry in report.gradeDistribution.entries)
              _BreakdownBar(
                label: entry.key,
                count: entry.value,
                total: gradeTotal,
              ),
          const SizedBox(height: 24),
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
      LoadStatus.initial || LoadStatus.loading => const LoadingView(
        message: 'Loading financial report...',
      ),
      LoadStatus.error => ErrorView(
        error: provider.financialError!,
        onRetry: () => provider.loadFinancial(),
      ),
      LoadStatus.success => _FinancialBody(
        report: provider.financial!,
        onRefresh: provider.loadFinancial,
      ),
    };
  }
}

class _FinancialBody extends StatelessWidget {
  final FinancialReport report;
  final Future<void> Function() onRefresh;

  const _FinancialBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final feeCountTotal =
        report.paidCount + report.partialCount + report.pendingCount;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Fees', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.check_circle_outline,
                  value: 'Rs ${report.totalCollected.toStringAsFixed(0)}',
                  label: 'Collected',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.schedule_outlined,
                  value: 'Rs ${report.totalPending.toStringAsFixed(0)}',
                  label: 'Pending',
                  color: Colors.orange,
                ),
                StatCard(
                  icon: Icons.receipt_long_outlined,
                  value: 'Rs ${report.totalInvoiced.toStringAsFixed(0)}',
                  label: 'Invoiced',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _BreakdownBar(
            label: 'Paid',
            count: report.paidCount,
            total: feeCountTotal,
          ),
          _BreakdownBar(
            label: 'Partial',
            count: report.partialCount,
            total: feeCountTotal,
          ),
          _BreakdownBar(
            label: 'Pending',
            count: report.pendingCount,
            total: feeCountTotal,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              'Payroll',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  value: 'Rs ${report.payrollTotalPaid.toStringAsFixed(0)}',
                  label: 'Paid',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.schedule_outlined,
                  value: 'Rs ${report.payrollTotalPending.toStringAsFixed(0)}',
                  label: 'Pending',
                  color: Colors.orange,
                ),
                StatCard(
                  icon: Icons.payments_outlined,
                  value: '${report.totalPayments}',
                  label: 'Total payments',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
      initialDateRange:
          widget.provider.attendanceStartDate != null &&
              widget.provider.attendanceEndDate != null
          ? DateTimeRange(
              start: widget.provider.attendanceStartDate!,
              end: widget.provider.attendanceEndDate!,
            )
          : null,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    widget.provider.loadAttendance(
      startDate: picked.start,
      endDate: picked.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final start = provider.attendanceStartDate;
    final end = provider.attendanceEndDate;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  start != null && end != null
                      ? '${_formatDate(start)} to ${_formatDate(end)}'
                      : 'All time',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickRange(context),
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Date range'),
              ),
              if (start != null)
                IconButton(
                  tooltip: 'Clear filter',
                  icon: const Icon(Icons.clear),
                  onPressed: () => provider.loadAttendance(),
                ),
            ],
          ),
        ),
        Expanded(
          child: switch (provider.attendanceStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(
              message: 'Loading attendance report...',
            ),
            LoadStatus.error => ErrorView(
              error: provider.attendanceError!,
              onRetry: () =>
                  provider.loadAttendance(startDate: start, endDate: end),
            ),
            LoadStatus.success => _AttendanceBody(
              report: provider.attendance!,
              onRefresh: () =>
                  provider.loadAttendance(startDate: start, endDate: end),
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.pie_chart_outline,
                  value: '${report.attendanceRate.toStringAsFixed(1)}%',
                  label: 'Attendance rate',
                ),
                StatCard(
                  icon: Icons.check_circle_outline,
                  value: '${report.present}',
                  label: 'Present',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.cancel_outlined,
                  value: '${report.absent}',
                  label: 'Absent',
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'By class & section',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (report.classBreakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No attendance records for this range.'),
            )
          else
            for (final entry in report.classBreakdown.entries)
              _BreakdownBar(
                label: entry.key,
                count: entry.value.present,
                total: entry.value.total,
              ),
          const SizedBox(height: 24),
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
      LoadStatus.initial || LoadStatus.loading => const LoadingView(
        message: 'Loading system report...',
      ),
      LoadStatus.error => ErrorView(
        error: provider.systemError!,
        onRetry: () => provider.loadSystem(),
      ),
      LoadStatus.success => _SystemBody(
        report: provider.system!,
        onRefresh: provider.loadSystem,
      ),
    };
  }
}

class _SystemBody extends StatelessWidget {
  final SystemReport report;
  final Future<void> Function() onRefresh;

  const _SystemBody({required this.report, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final actionTotal = report.actionBreakdown.values.fold(0, (a, b) => a + b);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StatCardRow(
              cards: [
                StatCard(
                  icon: Icons.groups_outlined,
                  value: '${report.totalStudents}',
                  label: 'Students',
                ),
                StatCard(
                  icon: Icons.badge_outlined,
                  value: '${report.totalTeachers}',
                  label: 'Teachers',
                ),
                StatCard(
                  icon: Icons.family_restroom_outlined,
                  value: '${report.totalParents}',
                  label: 'Parents',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Recent activity by category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (actionTotal == 0)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No audit log entries yet.'),
            )
          else
            for (final entry in report.actionBreakdown.entries)
              _BreakdownBar(
                label: entry.key,
                count: entry.value,
                total: actionTotal,
              ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Recent log entries',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (report.recentLogs.isEmpty)
            const EmptyStateView(
              message: 'No recent activity',
              icon: Icons.history,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final log in report.recentLogs) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        dense: true,
                        title: Text(log.action),
                        subtitle: Text('${log.user} · ${log.category}'),
                        trailing: Text(
                          log.status,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
