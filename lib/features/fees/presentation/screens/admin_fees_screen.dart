import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../providers/fee_provider.dart';
import 'fee_form_dialog.dart';

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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Export fees',
            onPressed: provider.isDownloading ? null : () => _downloadExport(context, provider, _statusFilter),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final entry in const {null: 'All', 'pending': 'Pending', 'partial': 'Partial', 'paid': 'Paid'}.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _statusFilter == entry.key,
                    onSelected: (_) {
                      setState(() => _statusFilter = entry.key);
                      provider.loadFees(status: entry.key);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (provider.status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading fees...'),
              LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadFees(status: _statusFilter)),
              LoadStatus.success => provider.fees.isEmpty
                  ? EmptyStateView(
                      message: 'No fees set up yet',
                      icon: Icons.receipt_long_outlined,
                      actionLabel: 'Add Fee',
                      onAction: () => showFeeFormDialog(context, provider),
                    )
                  : ListView.builder(
                      itemCount: provider.fees.length,
                      itemBuilder: (context, index) => _FeeTile(fee: provider.fees[index], provider: provider),
                    ),
            },
          ),
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
    final studentLabel = fee.studentName ?? fee.admissionNumber ?? fee.studentId;
    return ExpansionTile(
      title: Text('${fee.title} — $studentLabel'),
      subtitle: Text(
        '${fee.className ?? ''} ${fee.section ?? ''} · Rs ${fee.totalAmount.toStringAsFixed(0)}'
        ' · ${fee.status[0].toUpperCase()}${fee.status.substring(1)}',
      ),
      children: [
        if (fee.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: Text(fee.description)),
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
                onPressed: () => showFeeFormDialog(context, provider, existing: fee),
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
    );
  }
}

Future<void> _confirmDelete(BuildContext context, FeeProvider provider, Fee fee) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete fee?'),
      content: Text('This will permanently delete "${fee.title}". This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
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
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete fee')),
    );
  }
}

Future<void> _downloadExport(BuildContext context, FeeProvider provider, String? status) async {
  final bytes = await provider.exportFees(status: status);
  if (bytes != null) {
    if (context.mounted) await saveBytesOrNotify(context, bytes, 'fees.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export fees')),
    );
  }
}
