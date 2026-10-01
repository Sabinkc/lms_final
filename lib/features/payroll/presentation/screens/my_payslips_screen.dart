import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/format_rs.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../providers/my_payslips_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

const _monthNames = [
  '',
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
];

/// Teacher self-service (`implementation_backlog.md` E8-F2) — payslip list
/// with an inline breakdown per row, same "no separate detail screen"
/// pattern `ExamsListScreen` uses (the already-loaded `GET /payroll/my`
/// list has every field a detail view would need).
class MyPayslipsScreen extends StatefulWidget {
  const MyPayslipsScreen({super.key});

  @override
  State<MyPayslipsScreen> createState() => _MyPayslipsScreenState();
}

class _MyPayslipsScreenState extends State<MyPayslipsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<MyPayslipsProvider>();
    Future.microtask(() => provider.loadMyPayslips());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyPayslipsProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Payslips'),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading payslips...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMyPayslips()),
          LoadStatus.success =>
            provider.payslips.isEmpty
                ? const EmptyStateView(message: 'No payslips generated yet', icon: Icons.receipt_outlined)
                : _buildBody(context, provider.payslips),
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Payroll> payslips) {
    final latest = payslips.first;
    final thisYear = payslips.where((p) => p.year == latest.year).toList();
    double sum(double Function(Payroll) f) => thisYear.fold<double>(0, (acc, p) => acc + f(p));

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        _LatestPayHighlight(payslip: latest),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'YEAR TO DATE',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
            ),
            Text(
              '${latest.year}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.readable(AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TintedStatTile(
                  label: 'Gross Paid',
                  value: formatRs(sum((p) => p.grossSalary)),
                  caption: '${thisYear.length} cycle${thisYear.length == 1 ? '' : 's'}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TintedStatTile(
                  label: 'Tax',
                  value: formatRs(sum((p) => p.deductions.tax)),
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TintedStatTile(
                  label: 'Provident Fund',
                  value: formatRs(sum((p) => p.deductions.providentFund)),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Payment History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final payslip in payslips) ...[_PayslipTile(payslip: payslip), const SizedBox(height: 10)],
      ],
    );
  }
}

const _paidGreen = Color(0xFF16A34A);
const _pendingOrange = Color(0xFFEA580C);

class _LatestPayHighlight extends StatelessWidget {
  final Payroll payslip;

  const _LatestPayHighlight({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final paid = payslip.status == 'paid';
    final white75 = Colors.white.withValues(alpha: 0.75);
    final paidLine = [
      if (payslip.paidAt != null) formatDisplayDate(payslip.paidAt!),
      if (payslip.paymentMethod.isNotEmpty) _labelize(payslip.paymentMethod),
    ].join(' · ');

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'LATEST PAYSLIP • ${_monthNames[payslip.month].toUpperCase()} ${payslip.year}',
                  style: TextStyle(color: white75, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              AppStatusPill(
                label: paid ? 'Disbursed' : 'Pending',
                icon: paid ? Icons.check_circle_outline : Icons.schedule,
                color: paid ? const Color(0xFFB9F6CA) : const Color(0xFFFFD180),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Take-home Pay', style: TextStyle(color: white75)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRs(payslip.netSalary),
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
            ),
          ),
          if (paidLine.isNotEmpty)
            Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 16, color: white75),
                const SizedBox(width: 6),
                Text(paidLine, style: TextStyle(color: white75)),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroFigure(label: 'Gross Earnings', value: formatRs(payslip.grossSalary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroFigure(
                  label: 'Deductions',
                  value: formatRs(payslip.totalDeductions),
                  valueColor: const Color(0xFFFFD180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFigure extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _HeroFigure({required this.label, required this.value, this.valueColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayslipTile extends StatelessWidget {
  final Payroll payslip;

  const _PayslipTile({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = payslip.status == 'paid';
    final statusColor = paid ? _paidGreen : _pendingOrange;
    final a = payslip.allowances;
    final d = payslip.deductions;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.receipt_long_outlined, color: context.readable(statusColor)),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  '${_monthNames[payslip.month]} ${payslip.year}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              AppStatusPill(label: paid ? 'Paid' : 'Pending', color: statusColor),
            ],
          ),
          subtitle: Text(
            'Net ${formatRs(payslip.netSalary)}'
            '${payslip.paidAt != null ? ' · ${formatDisplayDate(payslip.paidAt!)}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          children: [
            _BreakdownGroup(
              title: 'Earnings',
              color: _paidGreen,
              rows: [
                ('Basic Salary', payslip.basicSalary),
                if (a.houseRent > 0) ('House Rent', a.houseRent),
                if (a.transport > 0) ('Transport', a.transport),
                if (a.medical > 0) ('Medical', a.medical),
                if (a.other > 0) ('Other Allowance', a.other),
                if (payslip.totalAllowances > 0 && a.houseRent + a.transport + a.medical + a.other == 0)
                  ('Allowances', payslip.totalAllowances),
              ],
              total: ('Gross Salary', payslip.grossSalary),
            ),
            const SizedBox(height: 10),
            _BreakdownGroup(
              title: 'Deductions',
              color: _pendingOrange,
              rows: [
                if (d.tax > 0) ('Tax', d.tax),
                if (d.providentFund > 0) ('Provident Fund', d.providentFund),
                if (d.absence > 0) ('Absence', d.absence),
                if (d.loan > 0) ('Loan', d.loan),
                if (d.other > 0) ('Other', d.other),
              ],
              total: ('Total Deductions', payslip.totalDeductions),
            ),
            const SizedBox(height: 10),
            InfoStrip(
              icon: Icons.account_balance_wallet_outlined,
              text: 'Net Salary',
              trailing: formatRs(payslip.netSalary),
            ),
            if (payslip.workingDays > 0) ...[
              const SizedBox(height: 8),
              InfoStrip(
                icon: Icons.event_available_outlined,
                text: '${payslip.presentDays}/${payslip.workingDays} days present',
                trailing: payslip.absentDays > 0 ? '${payslip.absentDays} absent' : null,
                color: AppColors.info,
              ),
            ],
            if (payslip.remarks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(alignment: Alignment.centerLeft, child: Text('Remarks: ${payslip.remarks}')),
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<(String, double)> rows;
  final (String, double) total;

  const _BreakdownGroup({required this.title, required this.color, required this.rows, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: context.readable(color), fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final (label, amount) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                  Text(formatRs(amount), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          const Divider(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(total.$1, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                formatRs(total.$2),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.readable(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `bank_transfer` → `Bank transfer`.
String _labelize(String raw) {
  final s = raw.replaceAll('_', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
