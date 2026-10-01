import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/format_rs.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pill_tabs.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee_payment.dart';
import '../providers/fee_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Payment Review'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: PillTabs<bool>(
                values: const [false, true],
                labelOf: (history) => history ? 'History' : 'Pending',
                iconOf: (history) => history ? Icons.history_rounded : Icons.pending_actions_rounded,
                selected: _showHistory,
                onSelected: (history) {
                  setState(() => _showHistory = history);
                  if (history && provider.historyStatus == LoadStatus.initial) provider.loadHistory();
                },
              ),
            ),
            Expanded(
              child: _showHistory ? _HistoryList(provider: provider) : _PendingQueue(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

const _approvedGreen = Color(0xFF16A34A);
const _pendingOrange = Color(0xFFEA580C);

Color _statusColor(BuildContext context, String status) => switch (status) {
      'approved' => _approvedGreen,
      'rejected' => Theme.of(context).colorScheme.error,
      _ => _pendingOrange,
    };

/// Payment-method display names (`esewa` → `eSewa`), falling back to
/// capitalizing whatever the backend sent.
String _methodLabel(String method) => switch (method.toLowerCase()) {
      'esewa' => 'eSewa',
      'khalti' => 'Khalti',
      'connectips' => 'ConnectIPS',
      'imepay' => 'IME Pay',
      'bank' || 'bank_transfer' => 'Bank Transfer',
      _ => _capitalize(method.replaceAll('_', ' ')),
    };

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _PendingQueue extends StatelessWidget {
  final FeeProvider provider;

  const _PendingQueue({required this.provider});

  @override
  Widget build(BuildContext context) {
    return switch (provider.pendingStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading pending payments...'),
      LoadStatus.error => ErrorView(error: provider.pendingError!, onRetry: () => provider.loadPendingPayments()),
      LoadStatus.success =>
        provider.pendingPayments.isEmpty
            ? const EmptyStateView(message: 'No pending payments to review', icon: Icons.task_alt_outlined)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _AwaitingHero(payments: provider.pendingPayments),
                  const SizedBox(height: 14),
                  for (final payment in provider.pendingPayments) ...[
                    _PaymentCard(payment: payment, provider: provider, reviewable: true),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
    };
  }
}

class _AwaitingHero extends StatelessWidget {
  final List<FeePayment> payments;

  const _AwaitingHero({required this.payments});

  @override
  Widget build(BuildContext context) {
    final total = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final white75 = Colors.white.withValues(alpha: 0.75);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 16, color: white75),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AWAITING VERIFICATION',
                  style: TextStyle(color: white75, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              AppStatusPill(label: '${payments.length} unverified', color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRs(total),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Across ${payments.length} submitted payment${payments.length == 1 ? '' : 's'}',
            style: TextStyle(color: white75),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final FeePayment payment;
  final FeeProvider provider;
  final bool reviewable;

  const _PaymentCard({required this.payment, required this.provider, required this.reviewable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = payment.submittedByName ?? payment.studentAdmissionNumber ?? 'Unknown payer';
    final statusColor = _statusColor(context, payment.status);
    final processing = provider.isProcessingPayment(payment.id);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initialsFor(name),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      if (payment.studentAdmissionNumber != null)
                        Text('Student ${payment.studentAdmissionNumber}', style: muted),
                    ],
                  ),
                ),
                AppStatusPill(
                  label: payment.status == 'pending' ? 'Pending Review' : _capitalize(payment.status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(payment.feeTitle ?? 'Fee', style: theme.textTheme.bodyMedium)),
                      Text(
                        formatRs(payment.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppStatusPill(label: _methodLabel(payment.method), color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.transactionPin,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (payment.createdAt.isNotEmpty) Text(formatDisplayDate(payment.createdAt), style: muted),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InfoStrip(icon: Icons.phone_iphone_rounded, text: 'Paid from ${payment.phoneNumber}', color: AppColors.info),
            if (payment.rejectionNote != null && payment.rejectionNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InfoStrip(
                icon: Icons.report_gmailerrorred_outlined,
                text: payment.rejectionNote!,
                color: theme.colorScheme.error,
              ),
            ],
            if (reviewable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Color.alphaBlend(
                          theme.colorScheme.error.withValues(alpha: 0.1),
                          theme.colorScheme.surface,
                        ),
                        foregroundColor: theme.colorScheme.error,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: processing ? null : () => _reject(context, provider, payment),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: processing ? null : () => _approve(context, provider, payment),
                      icon: processing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Approve'),
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

class _HistoryList extends StatefulWidget {
  final FeeProvider provider;

  const _HistoryList({required this.provider});

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return switch (provider.historyStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading history...'),
      LoadStatus.error => ErrorView(error: provider.historyError!, onRetry: () => provider.loadHistory()),
      LoadStatus.success =>
        provider.history.isEmpty
            ? const EmptyStateView(message: 'No payments submitted yet', icon: Icons.history)
            : () {
                final counts = <String, int>{};
                for (final p in provider.history) {
                  counts[p.status] = (counts[p.status] ?? 0) + 1;
                }
                final statuses = [for (final s in const ['approved', 'pending', 'rejected']) if (counts.containsKey(s)) s];
                final status = statuses.contains(_status) ? _status : null;
                final visible = [
                  for (final p in provider.history)
                    if (status == null || p.status == status) p,
                ];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    AppFilterChipBar<String?>(
                      options: [null, ...statuses],
                      selected: status,
                      labelBuilder: (s) => s == null ? 'All' : _capitalize(s),
                      countBuilder: (s) => s == null ? provider.history.length : counts[s]!,
                      onSelected: (s) => setState(() => _status = s),
                    ),
                    const SizedBox(height: 12),
                    for (final payment in visible) ...[
                      _PaymentCard(payment: payment, provider: provider, reviewable: false),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }(),
    };
  }
}

Future<void> _approve(BuildContext context, FeeProvider provider, FeePayment payment) async {
  final succeeded = await provider.approvePayment(payment.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.paymentActionError?.message ?? 'Failed to approve payment')));
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

  final succeeded = await provider.rejectPayment(
    payment.id,
    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
  );
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.paymentActionError?.message ?? 'Failed to reject payment')));
  }
}
