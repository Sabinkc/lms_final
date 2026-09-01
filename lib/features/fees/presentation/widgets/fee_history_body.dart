import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../providers/self_fee_provider.dart';
import '../screens/pay_fee_dialog.dart';

/// Shared summary + fee list, used by both Student "My Fees" and Parent
/// "Child's Fees" — same [SelfFeeProvider] state either way, mirroring
/// `AttendanceHistoryBody`. Unlike that widget this one takes the provider
/// directly rather than plain fields, since each fee/installment row needs
/// its own "Pay" action wired to [showPayFeeDialog] and a payment-status
/// lookup (`provider.paymentFor`).
class FeeHistoryBody extends StatelessWidget {
  final SelfFeeProvider provider;

  const FeeHistoryBody({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.feesStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading fees...'),
      LoadStatus.error => ErrorView(error: provider.feesError!, onRetry: () => provider.loadOwnFees()),
      LoadStatus.success => provider.fees.isEmpty
          ? const EmptyStateView(message: 'No fees recorded yet', icon: Icons.receipt_long_outlined)
          : ListView(
              children: [
                _SummaryCard(summary: provider.summary!, paymentQrUrl: provider.paymentQrUrl),
                for (final fee in provider.fees) _FeeCard(fee: fee, provider: provider),
              ],
            ),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final FeesSummary summary;
  final String? paymentQrUrl;

  const _SummaryCard({required this.summary, required this.paymentQrUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Rs ${summary.totalDue.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium),
            const Text('total due'),
            const SizedBox(height: 12),
            Text(
              '${summary.pending} pending · ${summary.partial} partial · ${summary.paid} paid (${summary.total} total)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (paymentQrUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Scan to pay, then submit the confirmation below'),
              const SizedBox(height: 8),
              Image.network(paymentQrUrl!, width: 160, height: 160, fit: BoxFit.contain),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final Fee fee;
  final SelfFeeProvider provider;

  const _FeeCard({required this.fee, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(fee.title),
        subtitle: Text('Rs ${fee.totalAmount.toStringAsFixed(0)} · ${fee.status[0].toUpperCase()}${fee.status.substring(1)}'),
        children: [
          if (fee.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft, child: Text(fee.description)),
            ),
          if (fee.isInstallment)
            for (final inst in fee.installments)
              _PayableRow(
                feeId: fee.id,
                installmentId: inst.id,
                title: inst.title,
                amount: inst.amount,
                dueDate: inst.dueDate,
                itemStatus: inst.status,
                provider: provider,
              )
          else
            _PayableRow(
              feeId: fee.id,
              installmentId: null,
              title: 'Full amount',
              amount: fee.remainingAmount,
              dueDate: fee.dueDate,
              itemStatus: fee.status,
              provider: provider,
            ),
        ],
      ),
    );
  }
}

class _PayableRow extends StatelessWidget {
  final String feeId;
  final String? installmentId;
  final String title;
  final double amount;
  final String dueDate;
  final String itemStatus;
  final SelfFeeProvider provider;

  const _PayableRow({
    required this.feeId,
    required this.installmentId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.itemStatus,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final submission = provider.paymentFor(feeId: feeId, installmentId: installmentId);

    Widget trailing;
    if (itemStatus == 'paid') {
      trailing = const Chip(label: Text('Paid'), side: BorderSide.none);
    } else if (submission != null && submission.status == 'pending') {
      trailing = const Chip(label: Text('Review pending'), side: BorderSide.none);
    } else {
      trailing = OutlinedButton(
        onPressed: () => showPayFeeDialog(
          context,
          provider,
          feeId: feeId,
          installmentId: installmentId,
          amount: amount,
        ),
        child: Text(submission?.status == 'rejected' ? 'Retry' : 'Pay'),
      );
    }

    return ListTile(
      dense: true,
      title: Text(title),
      subtitle: Text(
        'Due $dueDate${submission?.status == 'rejected' ? ' · Last attempt rejected${submission!.rejectionNote != null ? ': ${submission.rejectionNote}' : ''}' : ''}',
      ),
      trailing: trailing,
    );
  }
}
