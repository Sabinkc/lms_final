import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
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

    return DefaultTabController(
      length: 2,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: BrandAppBar(
            title: 'Payroll',
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Salary Config'),
                Tab(text: 'Payroll'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showActions(context, provider),
            child: const Icon(Icons.add),
          ),
          body: TabBarView(
            children: [
              _SalaryConfigTab(provider: provider),
              _PayrollTab(provider: provider),
            ],
          ),
        ),
      ),
    );
  }
}

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
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.configs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final config = provider.configs[index];
                  final accent = Theme.of(context).colorScheme.primary;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent.withValues(alpha: 0.14),
                        child: Icon(Icons.badge_outlined, color: accent),
                      ),
                      title: Text(config.staffName ?? config.staffId, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text(
                        'Rs ${config.basicSalary.toStringAsFixed(0)} basic · PF ${config.pfRate.toStringAsFixed(0)}%'
                        ' · Tax ${config.taxRate.toStringAsFixed(0)}%',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Update',
                        onPressed: () => showSalaryConfigDialog(context, provider, existing: config),
                      ),
                    ),
                  );
                },
              ),
    };
  }
}

class _PayrollTab extends StatelessWidget {
  final PayrollProvider provider;

  const _PayrollTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.payrollsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading payroll...'),
      LoadStatus.error => ErrorView(error: provider.payrollsError!, onRetry: () => provider.loadPayrolls()),
      LoadStatus.success =>
        provider.payrolls.isEmpty
            ? const EmptyStateView(message: 'No payroll generated yet', icon: Icons.payments_outlined)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  if (provider.summary != null) ...[
                    _SummaryCards(summary: provider.summary!),
                    const SizedBox(height: 16),
                  ],
                  for (final payroll in provider.payrolls) ...[
                    _PayrollTile(payroll: payroll, provider: provider),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
    };
  }
}

class _SummaryCards extends StatelessWidget {
  final PayrollSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return StatCardRow(
      cards: [
        StatCard(
          icon: Icons.account_balance_wallet_outlined,
          value: 'Rs ${summary.totalNetSalary.toStringAsFixed(0)}',
          label: 'Total Net',
          color: Theme.of(context).colorScheme.primary,
        ),
        StatCard(
          icon: Icons.check_circle_outline,
          value: 'Rs ${summary.totalPaid.toStringAsFixed(0)}',
          label: 'Paid',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.schedule_outlined,
          value: 'Rs ${summary.totalPending.toStringAsFixed(0)}',
          label: 'Pending',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _PayrollTile extends StatelessWidget {
  final Payroll payroll;
  final PayrollProvider provider;

  const _PayrollTile({required this.payroll, required this.provider});

  @override
  Widget build(BuildContext context) {
    final processing = provider.isProcessingPayroll(payroll.id);
    final statusColor = payroll.status == 'paid' ? Colors.green : Colors.orange;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withValues(alpha: 0.16),
                  foregroundColor: statusColor,
                  child: const Icon(Icons.receipt_long_outlined, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${payroll.staffName ?? payroll.staffId} — ${_monthNames[payroll.month]} ${payroll.year}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                AppStatusChip(label: payroll.status[0].toUpperCase() + payroll.status.substring(1), color: statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text('Net Rs ${payroll.netSalary.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),
            if (payroll.status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: processing ? null : () => provider.deletePayroll(payroll.id),
                  ),
                  FilledButton(
                    onPressed: processing ? null : () => provider.markAsPaid(payroll.id),
                    child: processing
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Mark Paid'),
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
