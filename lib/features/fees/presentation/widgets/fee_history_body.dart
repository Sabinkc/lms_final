import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../providers/self_fee_provider.dart';
import '../screens/pay_fee_dialog.dart';
import 'fee_dashboard_widgets.dart';

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
      LoadStatus.success =>
        provider.fees.isEmpty
            ? const EmptyStateView(message: 'No fees recorded yet', icon: Icons.receipt_long_outlined)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SummaryCard(summary: provider.summary!, paymentQrUrl: provider.paymentQrUrl),
                  const SizedBox(height: AppSpacing.lg),
                  for (final fee in provider.fees) ...[
                    _FeeCard(fee: fee, provider: provider),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
    };
  }
}

/// Same tinted cards and `Rs. 24,80,000` amounts as the Admin Fees screen.
class _SummaryCard extends StatelessWidget {
  final FeesSummary summary;
  final String? paymentQrUrl;

  const _SummaryCard({required this.summary, required this.paymentQrUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String fees(int n) => '($n ${n == 1 ? 'fee' : 'fees'})';
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // 2×2 on phones, one row of 4 on tablets / wide windows.
          crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.35,
          children: [
            FeeStatCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Due',
              value: formatRs(summary.totalDue),
              caption: fees(summary.total),
              color: FeeColors.pending,
              emphasize: true,
            ),
            FeeStatCard(
              icon: Icons.schedule_rounded,
              label: 'Pending',
              value: '${summary.pending}',
              caption: fees(summary.pending),
              color: FeeColors.pending,
            ),
            FeeStatCard(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Partial',
              value: '${summary.partial}',
              caption: fees(summary.partial),
              color: FeeColors.partial,
            ),
            FeeStatCard(
              icon: Icons.check_circle_rounded,
              label: 'Paid',
              value: '${summary.paid}',
              caption: fees(summary.paid),
              color: FeeColors.paid,
            ),
          ],
        ),
        if (paymentQrUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Scan to pay, then submit the confirmation below',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(paymentQrUrl!, width: 160, height: 160, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeeCard extends StatelessWidget {
  final Fee fee;
  final SelfFeeProvider provider;

  const _FeeCard({required this.fee, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (fee.status) {
      'paid' => FeeColors.paid,
      'partial' => FeeColors.partial,
      _ => FeeColors.pending,
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(Icons.receipt_long_rounded, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(fee.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(formatRs(fee.totalAmount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (fee.dueDate.isNotEmpty) 'Due ${formatDisplayDate(fee.dueDate)}',
                    if (fee.remainingAmount > 0 && fee.status != 'paid') '${formatRs(fee.remainingAmount)} left',
                  ].join('  •  '),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              AppStatusChip(label: fee.status[0].toUpperCase() + fee.status.substring(1), color: statusColor),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          if (fee.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      trailing = const AppStatusChip(label: 'Paid', color: FeeColors.paid);
    } else if (submission != null && submission.status == 'pending') {
      trailing = const AppStatusChip(label: 'Review pending', color: FeeColors.partial);
    } else {
      trailing = FilledButton(
        style: FilledButton.styleFrom(shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
        onPressed: () =>
            showPayFeeDialog(context, provider, feeId: feeId, installmentId: installmentId, amount: amount),
        child: Text(submission?.status == 'rejected' ? 'Retry' : 'Pay'),
      );
    }

    return ListTile(
      dense: true,
      title: Text('$title  •  ${formatRs(amount)}'),
      subtitle: Text(
        'Due ${formatDisplayDate(dueDate)}'
        '${submission?.status == 'rejected' ? ' · Last attempt rejected${submission!.rejectionNote != null ? ': ${submission.rejectionNote}' : ''}' : ''}',
      ),
      trailing: trailing,
    );
  }
}
