import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee_payment.dart';
import '../providers/fee_provider.dart';

/// Admin: pending-payments review queue (`implementation_backlog.md`
/// E7-F2) plus a read-only full history tab backed by `GET
/// /payments/history` — the "full audit trail" E7-F2-T3 calls for, kept on
/// this same screen rather than a separate route since it's the same
/// Admin-only payment-review concern.
class PaymentReviewScreen extends StatefulWidget {
  const PaymentReviewScreen({super.key});

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FeeProvider>();
    Future.microtask(() => provider.loadPendingPayments());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Review')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Pending')),
                ButtonSegment(value: true, label: Text('History')),
              ],
              selected: {_showHistory},
              onSelectionChanged: (selection) {
                setState(() => _showHistory = selection.first);
                if (selection.first && provider.historyStatus == LoadStatus.initial) provider.loadHistory();
              },
            ),
          ),
          Expanded(child: _showHistory ? _HistoryList(provider: provider) : _PendingQueue(provider: provider)),
        ],
      ),
    );
  }
}

class _PendingQueue extends StatelessWidget {
  final FeeProvider provider;

  const _PendingQueue({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.pendingStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading pending payments...'),
      LoadStatus.error =>
        ErrorView(error: provider.pendingError!, onRetry: () => provider.loadPendingPayments()),
      LoadStatus.success => provider.pendingPayments.isEmpty
          ? const EmptyStateView(message: 'No pending payments to review', icon: Icons.task_alt_outlined)
          : ListView.builder(
              itemCount: provider.pendingPayments.length,
              itemBuilder: (context, index) {
                final payment = provider.pendingPayments[index];
                final processing = provider.isProcessingPayment(payment.id);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.feeTitle ?? 'Fee', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Rs ${payment.amount.toStringAsFixed(0)} · ${payment.method}'),
                        Text('Phone: ${payment.phoneNumber} · PIN/Ref: ${payment.transactionPin}'),
                        if (payment.submittedByName != null) Text('Submitted by: ${payment.submittedByName}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: processing ? null : () => _reject(context, provider, payment),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: processing ? null : () => _approve(context, provider, payment),
                              child: processing
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    };
  }
}

class _HistoryList extends StatelessWidget {
  final FeeProvider provider;

  const _HistoryList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.historyStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading history...'),
      LoadStatus.error => ErrorView(error: provider.historyError!, onRetry: () => provider.loadHistory()),
      LoadStatus.success => provider.history.isEmpty
          ? const EmptyStateView(message: 'No payments submitted yet', icon: Icons.history)
          : ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final payment = provider.history[index];
                return ListTile(
                  title: Text(payment.feeTitle ?? 'Fee'),
                  subtitle: Text('Rs ${payment.amount.toStringAsFixed(0)} · ${payment.submittedByName ?? ''}'),
                  trailing: _StatusChip(status: payment.status),
                );
              },
            ),
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Theme.of(context).colorScheme.error,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(status[0].toUpperCase() + status.substring(1)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}

Future<void> _approve(BuildContext context, FeeProvider provider, FeePayment payment) async {
  final succeeded = await provider.approvePayment(payment.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.paymentActionError?.message ?? 'Failed to approve payment')),
    );
  }
}

Future<void> _reject(BuildContext context, FeeProvider provider, FeePayment payment) async {
  final noteController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reject payment?'),
      content: TextField(
        controller: noteController,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Reject')),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final succeeded =
      await provider.rejectPayment(payment.id, note: noteController.text.trim().isEmpty ? null : noteController.text.trim());
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.paymentActionError?.message ?? 'Failed to reject payment')),
    );
  }
}
