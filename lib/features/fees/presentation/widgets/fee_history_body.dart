import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_chip.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StatCardRow(cards: [
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              value: 'Rs ${summary.totalDue.toStringAsFixed(0)}',
              label: 'Total Due',
              color: scheme.primary,
            ),
            StatCard(icon: Icons.schedule_outlined, value: '${summary.pending}', label: 'Pending', color: Colors.orange),
            StatCard(icon: Icons.hourglass_bottom_outlined, value: '${summary.partial}', label: 'Partial', color: scheme.secondary),
            StatCard(icon: Icons.check_circle_outline, value: '${summary.paid}', label: 'Paid', color: Colors.green),
          ]),
          if (paymentQrUrl != null) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Scan to pay, then submit the confirmation below', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(paymentQrUrl!, width: 160, height: 160, fit: BoxFit.contain),
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

class _FeeCard extends StatelessWidget {
  final Fee fee;
  final SelfFeeProvider provider;

  const _FeeCard({required this.fee, required this.provider});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (fee.status) {
      'paid' => Colors.green,
      'partial' => Colors.orange,
      _ => Theme.of(context).colorScheme.error,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(fee.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text('Rs ${fee.totalAmount.toStringAsFixed(0)}'),
              AppStatusChip(label: fee.status[0].toUpperCase() + fee.status.substring(1), color: statusColor),
            ],
          ),
        ),
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
      trailing = const AppStatusChip(label: 'Paid', color: Colors.green);
    } else if (submission != null && submission.status == 'pending') {
      trailing = const AppStatusChip(label: 'Review pending', color: Colors.orange);
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
