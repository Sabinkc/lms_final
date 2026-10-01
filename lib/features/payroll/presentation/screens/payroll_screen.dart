import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/format_rs.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/pill_tabs.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../../data/models/staff_salary_config.dart';
import '../providers/payroll_provider.dart';
import 'generate_payroll_dialog.dart';
import 'salary_config_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

const _monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Admin: Teacher Salary/Payroll management (`implementation_backlog.md`
/// E8-F1) — Salary Config and generated Payroll are two tabs of one screen
/// since they're the same workflow (a config must exist before a payroll
/// can be generated for that teacher).
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PayrollProvider>();
    Future.microtask(() {
      provider.loadSalaryConfigs();
      provider.loadPayrolls();
    });
  }

  void _showActions(BuildContext context, PayrollProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Set Salary Config'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showSalaryConfigDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Generate Payroll'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showGeneratePayrollDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Generate for All Staff'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _generateBulk(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBulk(BuildContext context, PayrollProvider provider) async {
    final now = DateTime.now();
    final succeeded = await provider.generateBulkPayroll(month: now.month, year: now.year);
    if (!context.mounted) return;
    final result = provider.lastBulkResult;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded && result != null
              ? 'Generated: ${result.$1} · Skipped: ${result.$2} · Failed: ${result.$3}'
              : provider.generateError?.message ?? 'Failed to generate bulk payroll',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Payroll'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showActions(context, provider),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: PillTabs<int>(
                values: const [0, 1],
                labelOf: (i) => i == 0 ? 'Salary Config' : 'Payroll Runs',
                iconOf: (i) => i == 0 ? Icons.tune_rounded : Icons.receipt_long_rounded,
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? _SalaryConfigTab(provider: provider)
                  : _PayrollTab(
                      provider: provider,
                      onGenerate: () => showGeneratePayrollDialog(context, provider),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

const _paidGreen = Color(0xFF16A34A);
const _pendingOrange = Color(0xFFEA580C);

double _allowancesTotal(PayrollAllowances a) => a.houseRent + a.transport + a.medical + a.other;

class _SalaryConfigTab extends StatelessWidget {
  final PayrollProvider provider;

  const _SalaryConfigTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.configsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading salary configs...'),
      LoadStatus.error => ErrorView(error: provider.configsError!, onRetry: () => provider.loadSalaryConfigs()),
      LoadStatus.success =>
        provider.configs.isEmpty
            ? const EmptyStateView(message: 'No salary configs set yet', icon: Icons.badge_outlined)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TintedStatTile(
                          icon: Icons.groups_outlined,
                          label: 'Staff configured',
                          value: '${provider.configs.length}',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TintedStatTile(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Monthly basic',
                          value: formatRs(provider.configs.fold<double>(0, (sum, c) => sum + c.basicSalary)),
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final config in provider.configs) ...[
                    _SalaryConfigCard(config: config, provider: provider),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
    };
  }
}

class _SalaryConfigCard extends StatelessWidget {
  final StaffSalaryConfig config;
  final PayrollProvider provider;

  const _SalaryConfigCard({required this.config, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = config.staffName ?? config.staffId;
    final allowances = _allowancesTotal(config.allowances);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Initials(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      if (config.staffEmail != null)
                        Text(
                          config.staffEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Update',
                  onPressed: () => showSalaryConfigDialog(context, provider, existing: config),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoStrip(
              icon: Icons.payments_outlined,
              text: 'Basic salary',
              trailing: formatRs(config.basicSalary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AppStatusPill(label: 'PF ${config.pfRate.toStringAsFixed(0)}%', color: AppColors.info),
                AppStatusPill(label: 'Tax ${config.taxRate.toStringAsFixed(0)}%', color: _pendingOrange),
                AppStatusPill(label: '${config.workingDays} working days', color: AppColors.primary),
                if (allowances > 0) AppStatusPill(label: '+${formatRs(allowances)} allowances', color: _paidGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollTab extends StatefulWidget {
  final PayrollProvider provider;
  final VoidCallback onGenerate;

  const _PayrollTab({required this.provider, required this.onGenerate});

  @override
  State<_PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<_PayrollTab> {
  /// `year * 100 + month`, or null for every month.
  int? _period;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return switch (provider.payrollsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading payroll...'),
      LoadStatus.error => ErrorView(error: provider.payrollsError!, onRetry: () => provider.loadPayrolls()),
      LoadStatus.success =>
        provider.payrolls.isEmpty
            ? EmptyStateView(
                message: 'No payroll generated yet',
                icon: Icons.payments_outlined,
                actionLabel: 'Generate Payroll',
                onAction: widget.onGenerate,
              )
            : _buildList(context, provider),
    };
  }

  Widget _buildList(BuildContext context, PayrollProvider provider) {
    final counts = <int, int>{};
    for (final p in provider.payrolls) {
      final key = p.year * 100 + p.month;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final periods = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    final period = periods.contains(_period) ? _period : null;
    final visible = [
      for (final p in provider.payrolls)
        if (period == null || p.year * 100 + p.month == period) p,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _PayrollHero(provider: provider, onGenerate: widget.onGenerate),
        const SizedBox(height: 14),
        if (periods.length > 1) ...[
          AppFilterChipBar<int?>(
            options: [null, ...periods],
            selected: period,
            labelBuilder: (k) => k == null ? 'All' : '${_monthNames[k % 100]} ${k ~/ 100}',
            countBuilder: (k) => k == null ? provider.payrolls.length : counts[k]!,
            onSelected: (k) => setState(() => _period = k),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Staff Disbursements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text('${visible.length} shown', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 10),
        for (final payroll in visible) ...[
          _PayrollTile(payroll: payroll, provider: provider),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PayrollHero extends StatelessWidget {
  final PayrollProvider provider;
  final VoidCallback onGenerate;

  const _PayrollHero({required this.provider, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final summary = provider.summary;
    final paidCount = provider.payrolls.where((p) => p.status == 'paid').length;
    final pendingCount = provider.payrolls.length - paidCount;
    final total = summary?.totalNetSalary ?? provider.payrolls.fold<double>(0, (sum, p) => sum + p.netSalary);
    final paid = summary?.totalPaid ?? 0;
    final fraction = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final white70 = Colors.white.withValues(alpha: 0.75);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL NET PAYROLL',
                      style: TextStyle(color: white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRs(total),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${provider.payrolls.length} payslips',
                      style: TextStyle(color: white70),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: const Color(0xFFFBBF24).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.circle, size: 9, color: Colors.white),
              const SizedBox(width: 5),
              Text('Paid $paidCount · ${formatRs(paid)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.circle, size: 9, color: Color(0xFFFBBF24)),
              const SizedBox(width: 5),
              Text(
                'Pending $pendingCount · ${formatRs(summary?.totalPending ?? 0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(46),
            ),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Generate Payroll'),
          ),
        ],
      ),
    );
  }
}

class _PayrollTile extends StatelessWidget {
  final Payroll payroll;
  final PayrollProvider provider;

  const _PayrollTile({required this.payroll, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final processing = provider.isProcessingPayroll(payroll.id);
    final paid = payroll.status == 'paid';
    final statusColor = paid ? _paidGreen : _pendingOrange;
    final name = payroll.staffName ?? payroll.staffId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Initials(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${_monthNames[payroll.month]} ${payroll.year} · ${payroll.presentDays}/${payroll.workingDays} days present',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Net ${formatRs(payroll.netSalary)}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    AppStatusPill(
                      label: paid ? 'Paid' : 'Pending',
                      icon: paid ? Icons.check_circle_outline : Icons.schedule,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoStrip(
              icon: Icons.receipt_outlined,
              text: 'Gross ${formatRs(payroll.grossSalary)}',
              trailing: '−${formatRs(payroll.totalDeductions)}',
              color: AppColors.info,
            ),
            if (paid) ...[
              const SizedBox(height: 8),
              InfoStrip(
                icon: Icons.account_balance_outlined,
                text: [
                  if (payroll.paymentMethod.isNotEmpty) _labelize(payroll.paymentMethod),
                  if (payroll.paidAt != null) 'Paid ${formatDisplayDate(payroll.paidAt!)}',
                ].join(' · ').ifEmpty('Paid'),
                color: _paidGreen,
              ),
            ] else ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: processing ? null : () => provider.deletePayroll(payroll.id),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: processing ? null : () => provider.markAsPaid(payroll.id),
                      icon: processing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Mark Paid'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `bank_transfer` → `Bank transfer`.
String _labelize(String raw) {
  final s = raw.replaceAll('_', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _Initials extends StatelessWidget {
  final String name;

  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        initialsFor(name),
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
