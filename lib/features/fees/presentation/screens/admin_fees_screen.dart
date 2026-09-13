import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/simple_bar_chart.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../../data/models/fee.dart';
import '../providers/fee_provider.dart';
import 'fee_form_dialog.dart';

const _statusFilterOptions = <String?>[null, 'pending', 'partial', 'paid'];

String _statusFilterLabel(String? status) => switch (status) {
  null => 'All',
  'pending' => 'Pending',
  'partial' => 'Partial',
  'paid' => 'Paid',
  _ => status,
};

const _monthAbbrevs = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Buckets [fees] by due-month (client-side, from data already loaded — no
/// new API call) so the header chart shows collected-vs-total per month
/// without a charting package. Falls back to omitting a fee whose `dueDate`
/// doesn't parse rather than guessing a month.
({List<double> collected, List<double> total, List<String> labels})
_monthlyBuckets(List<Fee> fees) {
  final byMonth = <DateTime, ({double collected, double total})>{};
  for (final fee in fees) {
    final parsed = DateTime.tryParse(fee.dueDate);
    if (parsed == null) continue;
    final key = DateTime(parsed.year, parsed.month);
    final existing = byMonth[key] ?? (collected: 0, total: 0);
    byMonth[key] = (
      collected: existing.collected + fee.paidAmount,
      total: existing.total + fee.totalAmount,
    );
  }
  final keys = byMonth.keys.toList()..sort();
  final recentKeys = keys.length > 6 ? keys.sublist(keys.length - 6) : keys;
  return (
    collected: [for (final k in recentKeys) byMonth[k]!.collected],
    total: [for (final k in recentKeys) byMonth[k]!.total],
    labels: [for (final k in recentKeys) _monthAbbrevs[k.month - 1]],
  );
}

/// Admin: Fee Structure Setup (`implementation_backlog.md` E7-F1). One fee
/// per student (see `FeeRepository`'s doc comment) — each row expands to
/// show its installment schedule when it has one, same inline-detail
/// pattern `ExamsListScreen` uses, since there's no separate fee-detail
/// screen either.
class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FeeProvider>();
    Future.microtask(() => provider.loadFees());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees'),
        actions: [
          IconButton(
            icon: provider.isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Export fees',
            onPressed: provider.isDownloading
                ? null
                : () => _downloadExport(context, provider, _statusFilter),
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Payment Review',
            onPressed: () => context.push(AppRoutes.adminFeePayments),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFeeFormDialog(context, provider),
        tooltip: 'Add Fee',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (provider.status == LoadStatus.success && provider.fees.isNotEmpty)
            _FeesSummary(fees: provider.fees),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AppFilterChipBar<String?>(
              options: _statusFilterOptions,
              selected: _statusFilter,
              labelBuilder: _statusFilterLabel,
              onSelected: (status) {
                setState(() => _statusFilter = status);
                provider.loadFees(status: status);
              },
            ),
          ),
          Expanded(
            child: switch (provider.status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(
                message: 'Loading fees...',
              ),
              LoadStatus.error => ErrorView(
                error: provider.error!,
                onRetry: () => provider.loadFees(status: _statusFilter),
              ),
              LoadStatus.success =>
                provider.fees.isEmpty
                    ? EmptyStateView(
                        message: 'No fees set up yet',
                        icon: Icons.receipt_long_outlined,
                        actionLabel: 'Add Fee',
                        onAction: () => showFeeFormDialog(context, provider),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: provider.fees.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) => _FeeTile(
                          fee: provider.fees[index],
                          provider: provider,
                        ),
                      ),
            },
          ),
        ],
      ),
    );
  }
}

/// Total/Collected/Pending stat cards plus a per-month collected-amount
/// chart — both computed client-side from `provider.fees` (already loaded
/// by this screen), no new backend call.
class _FeesSummary extends StatelessWidget {
  final List<Fee> fees;

  const _FeesSummary({required this.fees});

  @override
  Widget build(BuildContext context) {
    final totalAmount = fees.fold<double>(0, (sum, f) => sum + f.totalAmount);
    final collected = fees.fold<double>(0, (sum, f) => sum + f.paidAmount);
    final pending = fees.fold<double>(0, (sum, f) => sum + f.remainingAmount);
    final buckets = _monthlyBuckets(fees);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          StatCardRow(
            cards: [
              StatCard(
                icon: Icons.account_balance_wallet_outlined,
                value: 'Rs ${totalAmount.toStringAsFixed(0)}',
                label: 'Total Fees',
                color: scheme.primary,
              ),
              StatCard(
                icon: Icons.check_circle_outline,
                value: 'Rs ${collected.toStringAsFixed(0)}',
                label: 'Collected',
                color: Colors.green,
              ),
              StatCard(
                icon: Icons.schedule_outlined,
                value: 'Rs ${pending.toStringAsFixed(0)}',
                label: 'Pending',
                color: Colors.orange,
              ),
            ],
          ),
          if (buckets.labels.length >= 2) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection by month',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    SimpleBarChart(
                      values: buckets.collected,
                      labels: buckets.labels,
                      barColor: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeeTile extends StatelessWidget {
  final Fee fee;
  final FeeProvider provider;

  const _FeeTile({required this.fee, required this.provider});

  @override
  Widget build(BuildContext context) {
    final studentLabel =
        fee.studentName ?? fee.admissionNumber ?? fee.studentId;
    final statusColor = switch (fee.status) {
      'paid' => Colors.green,
      'partial' => Colors.orange,
      _ => Theme.of(context).colorScheme.error,
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text('${fee.title} — $studentLabel'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '${fee.className ?? ''} ${fee.section ?? ''} · Rs ${fee.totalAmount.toStringAsFixed(0)}',
              ),
              AppStatusChip(
                label: fee.status[0].toUpperCase() + fee.status.substring(1),
                color: statusColor,
              ),
            ],
          ),
        ),
        children: [
          if (fee.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(fee.description),
              ),
            ),
          if (fee.isInstallment)
            for (final inst in fee.installments)
              ListTile(
                dense: true,
                title: Text(inst.title),
                subtitle: Text('Due ${inst.dueDate} · ${inst.status}'),
                trailing: Text('Rs ${inst.amount.toStringAsFixed(0)}'),
              )
          else
            ListTile(
              dense: true,
              title: const Text('Due date'),
              trailing: Text(fee.dueDate),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () =>
                      showFeeFormDialog(context, provider, existing: fee),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, provider, fee),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  FeeProvider provider,
  Fee fee,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete fee?'),
      content: Text(
        'This will permanently delete "${fee.title}". This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final succeeded = await provider.deleteFee(fee.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.actionError?.message ?? 'Failed to delete fee'),
      ),
    );
  }
}

Future<void> _downloadExport(
  BuildContext context,
  FeeProvider provider,
  String? status,
) async {
  final bytes = await provider.exportFees(status: status);
  if (bytes != null) {
    if (context.mounted) await saveBytesOrNotify(context, bytes, 'fees.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.downloadError?.message ?? 'Failed to export fees',
        ),
      ),
    );
  }
}
