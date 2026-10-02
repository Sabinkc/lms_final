import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/fee.dart';
import '../../data/models/fee_payment.dart';
import '../providers/fee_provider.dart';
import '../widgets/fee_dashboard_widgets.dart';
import 'fee_form_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/utils/capitalize.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../widgets/fee_progress_bar.dart';

const _statusFilterOptions = <String?>[null, 'pending', 'partial', 'paid'];

String _statusFilterLabel(String? status) => switch (status) {
  null => 'All',
  'pending' => 'Pending',
  'partial' => 'Partial',
  'paid' => 'Paid',
  _ => status,
};

const _monthAbbrevs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Buckets [fees] by due-month (client-side, from data already loaded — no
/// new API call) so the header chart shows collected-vs-total per month
/// without a charting package. Falls back to omitting a fee whose `dueDate`
/// doesn't parse rather than guessing a month.
({List<double> collected, List<double> pending, List<String> labels}) _monthlyBuckets(List<Fee> fees) {
  final byMonth = <DateTime, ({double collected, double total})>{};
  for (final fee in fees) {
    final parsed = DateTime.tryParse(fee.dueDate);
    if (parsed == null) continue;
    final key = DateTime(parsed.year, parsed.month);
    final existing = byMonth[key] ?? (collected: 0, total: 0);
    byMonth[key] = (collected: existing.collected + fee.paidAmount, total: existing.total + fee.totalAmount);
  }
  final keys = byMonth.keys.toList()..sort();
  final recentKeys = keys.length > 6 ? keys.sublist(keys.length - 6) : keys;
  return (
    collected: [for (final k in recentKeys) byMonth[k]!.collected],
    pending: [for (final k in recentKeys) byMonth[k]!.total - byMonth[k]!.collected],
    labels: [for (final k in recentKeys) _monthAbbrevs[k.month - 1]],
  );
}

bool _isToday(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return false;
  final now = DateTime.now();
  return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
}

/// Admin: Fee Structure Setup (`implementation_backlog.md` E7-F1). One fee
/// per student (see `FeeRepository`'s doc comment) — each row expands to
/// show its installment schedule when it has one, same inline-detail
/// pattern `ExamsListScreen` uses, since there's no separate fee-detail
/// screen either.
///
/// Restyled 2026-09-29, and matched much more closely 2026-09-30, to a
/// reference dashboard design the user supplied (`LMS UI/WhatsApp Image
/// ... 4.20.28 PM.jpeg`): tinted stat cards, a boxed Quick Actions panel,
/// a stacked collected-vs-pending chart, a Fee Status ring, and Recent Fee
/// Collections — all from real data this screen (or `FeeProvider.history`,
/// already used by Payment Review) already has. Laid out single-column for
/// phones (the reference is a wide layout: 4 stat cards and chart+ring side
/// by side). Left out rather than invented: no academic-year picker (no
/// such field on `Fee`), no "Create Invoice"/"Fee Reports" actions (no such
/// features), and the literal 6-column table became one stacked row per
/// payment. "Payment Method" will only ever show "eSewa" for every row:
/// `submitFeePayment` hardcodes that server-side regardless of what's sent
/// (documented finding, not a client bug).
class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  String? _statusFilter;
  final _searchController = TextEditingController();
  final _feeListKey = GlobalKey();
  String _query = '';

  final _scrollController = ScrollController();

  /// "View Due Students" filters the fee list further down the page — jump
  /// to it so the tap visibly does something. The `ListView` builds lazily,
  /// so the heading may not exist yet: page down until it does, then settle
  /// on it.
  Future<void> _showDueStudents() async {
    setState(() => _statusFilter = 'pending');
    for (var i = 0; i < 20 && mounted; i++) {
      final target = _feeListKey.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        return;
      }
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent) return;
      await _scrollController.animateTo(
        (position.pixels + position.viewportDimension).clamp(0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<FeeProvider>();
    Future.microtask(() {
      provider.loadFees();
      provider.loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<FeeProvider>();
    await Future.wait([provider.loadFees(silent: true), provider.loadHistory(silent: true)]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeeProvider>();

    // Status filtering is client-side over the full list: reloading from the
    // server per chip would also shrink the stat cards, charts and chip
    // counts above, which all read the same `provider.fees`.
    final visibleFees = provider.fees.where((f) {
      if (_statusFilter != null && f.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return (f.studentName ?? '').toLowerCase().contains(q) ||
          (f.admissionNumber ?? '').toLowerCase().contains(q) ||
          (f.className ?? '').toLowerCase().contains(q);
    }).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Fees'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.status) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading fees...'),
            LoadStatus.error => ErrorView(error: provider.error!, onRetry: provider.loadFees),
            LoadStatus.success => ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const _FeesHeader(),
                const SizedBox(height: AppSpacing.lg),
                if (provider.fees.isNotEmpty) ...[
                  _FeesSummary(fees: provider.fees, history: provider.history),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _QuickActions(
                  isDownloading: provider.isDownloading,
                  onAddFee: () => showFeeFormDialog(context, provider),
                  onViewDue: _showDueStudents,
                  onReviewPayments: () => context.push(AppRoutes.adminFeePayments),
                  onExport: () => _downloadExport(context, provider, _statusFilter),
                ),
                if (provider.fees.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _MonthlyChart(fees: provider.fees),
                  const SizedBox(height: AppSpacing.lg),
                  _FeeStatusCard(fees: provider.fees),
                ],
                if (provider.history.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _RecentCollections(payments: provider.history, fees: provider.fees),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Fee Structure',
                  key: _feeListKey,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                AppFilterChipBar<String?>(
                  options: _statusFilterOptions,
                  selected: _statusFilter,
                  labelBuilder: _statusFilterLabel,
                  countBuilder: (status) =>
                      status == null ? provider.fees.length : provider.fees.where((f) => f.status == status).length,
                  onSelected: (status) => setState(() => _statusFilter = status),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, class or roll no...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (visibleFees.isEmpty)
                  EmptyStateView(
                    message: provider.fees.isEmpty ? 'No fees set up yet' : 'No fees match this filter',
                    icon: Icons.receipt_long_outlined,
                    actionLabel: provider.fees.isEmpty ? 'Add Fee' : null,
                    onAction: provider.fees.isEmpty ? () => showFeeFormDialog(context, provider) : null,
                  )
                else
                  for (final fee in visibleFees) ...[_FeeTile(fee: fee, provider: provider), const SizedBox(height: 8)],
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _FeesHeader extends StatelessWidget {
  const _FeesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fees', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(
                'Track fee collection, dues and financial records.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Total/Collected/Pending/Today's-Collection stat cards plus a per-month
/// collected-amount chart — all computed client-side from data this screen
/// already loaded, no new backend call. "Today's Collection" sums approved
/// [FeePayment]s submitted today (`createdAt`), matching how "collection"
/// reads to an Admin — money that came in today — rather than `reviewedAt`,
/// which is null until someone reviews it.
class _FeesSummary extends StatelessWidget {
  final List<Fee> fees;
  final List<FeePayment> history;

  const _FeesSummary({required this.fees, required this.history});

  @override
  Widget build(BuildContext context) {
    final totalAmount = fees.fold<double>(0, (sum, f) => sum + f.totalAmount);
    final collected = fees.fold<double>(0, (sum, f) => sum + f.paidAmount);
    final pending = fees.fold<double>(0, (sum, f) => sum + f.remainingAmount);
    final collectedPct = totalAmount > 0 ? (collected / totalAmount * 100) : 0;
    final pendingPct = totalAmount > 0 ? (pending / totalAmount * 100) : 0;

    final todaysPayments = history.where((p) => p.status == 'approved' && _isToday(p.createdAt)).toList();
    final todaysTotal = todaysPayments.fold<double>(0, (sum, p) => sum + p.amount);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      children: [
        FeeStatCard(
          icon: Icons.savings_rounded,
          label: 'Total Fees',
          value: formatRs(totalAmount),
          caption: '(${fees.length} ${fees.length == 1 ? 'fee' : 'fees'})',
          color: AppColors.primary,
        ),
        FeeStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Collected',
          value: formatRs(collected),
          caption: '(${collectedPct.toStringAsFixed(1)}%)',
          color: FeeColors.paid,
          emphasize: true,
        ),
        FeeStatCard(
          icon: Icons.schedule_rounded,
          label: 'Pending',
          value: formatRs(pending),
          caption: '(${pendingPct.toStringAsFixed(1)}%)',
          color: FeeColors.pending,
          emphasize: true,
        ),
        FeeStatCard(
          icon: Icons.calendar_month_rounded,
          label: "Today's Collection",
          value: formatRs(todaysTotal),
          caption: '(${todaysPayments.length} ${todaysPayments.length == 1 ? 'payment' : 'payments'})',
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isDownloading;
  final VoidCallback onAddFee;
  final VoidCallback onViewDue;
  final VoidCallback onReviewPayments;
  final VoidCallback onExport;

  const _QuickActions({
    required this.isDownloading,
    required this.onAddFee,
    required this.onViewDue,
    required this.onReviewPayments,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: context.readable(AppColors.primary)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.1,
            children: [
              _ActionTile(
                icon: Icons.add_rounded,
                title: 'Add Fee',
                subtitle: 'Create a new fee',
                filled: true,
                onTap: onAddFee,
              ),
              _ActionTile(
                icon: Icons.groups_rounded,
                title: 'View Due Students',
                subtitle: 'Check pending fees',
                onTap: onViewDue,
              ),
              _ActionTile(
                icon: Icons.fact_check_rounded,
                title: 'Review Payments',
                subtitle: 'Approve pending',
                onTap: onReviewPayments,
              ),
              _ActionTile(
                icon: isDownloading ? Icons.hourglass_top_rounded : Icons.bar_chart_rounded,
                title: 'Export Fees',
                subtitle: 'Download as Excel',
                onTap: isDownloading ? null : onExport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal icon + title + subtitle tile — the first ("primary") action is
/// filled green, the rest are outlined, as in the reference.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = filled ? Colors.white : theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(AppRadius.xl);
    return PressScale(
      child: Material(
        color: filled ? AppColors.primary : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: filled ? BorderSide.none : BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: filled ? Colors.white : AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Fee> fees;

  const _MonthlyChart({required this.fees});

  @override
  Widget build(BuildContext context) {
    final buckets = _monthlyBuckets(fees);
    if (buckets.labels.isEmpty) return const SizedBox.shrink();

    // Legend sits above the plot, not beside the title — at phone width the
    // two don't fit on one line without truncating the title.
    return _SectionCard(
      icon: Icons.stacked_bar_chart_rounded,
      title: 'Fee Collection Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Wrap(
            spacing: AppSpacing.md,
            children: [
              FeeLegendDot(color: FeeColors.paid, label: 'Collected'),
              FeeLegendDot(color: FeeColors.pendingBar, label: 'Pending'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FeeStackedBarChart(labels: buckets.labels, collected: buckets.collected, pending: buckets.pending),
        ],
      ),
    );
  }
}

/// Fee amounts grouped by the fee's own status (paid/partial/pending), as a
/// ring with the grand total in the middle.
class _FeeStatusCard extends StatelessWidget {
  final List<Fee> fees;

  const _FeeStatusCard({required this.fees});

  @override
  Widget build(BuildContext context) {
    double sumFor(String status) =>
        fees.where((f) => f.status == status).fold<double>(0, (sum, f) => sum + f.totalAmount);
    final total = fees.fold<double>(0, (sum, f) => sum + f.totalAmount);

    return _SectionCard(
      icon: Icons.donut_large_rounded,
      title: 'Fee Status',
      child: FeeStatusDonut(
        total: total,
        slices: [
          (label: 'Paid', amount: sumFor('paid'), color: FeeColors.paid),
          (label: 'Partial', amount: sumFor('partial'), color: FeeColors.partial),
          (label: 'Pending', amount: sumFor('pending'), color: FeeColors.pending),
        ],
      ),
    );
  }
}

/// Card with the reference's section header: soft icon badge + bold title,
/// optional trailing widget (legend / "View All") on the right.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets childPadding;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.trailing,
    required this.child,
    this.childPadding = const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, size: 18, color: context.readable(AppColors.primary)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(padding: childPadding, child: child),
        ],
      ),
    );
  }
}

/// Real payment transactions ([FeeProvider.history], the same data Payment
/// Review's audit trail uses) — cross-referenced against [fees] (already
/// loaded by this screen) to show the student's name/class, since
/// [FeePayment] itself only carries an admission number, not a name. The
/// reference's 6-column table is a stacked row per payment here: the same
/// fields (date, student, class, amount, method, status) at phone width.
class _RecentCollections extends StatelessWidget {
  final List<FeePayment> payments;
  final List<Fee> fees;

  const _RecentCollections({required this.payments, required this.fees});

  @override
  Widget build(BuildContext context) {
    final feeById = {for (final f in fees) f.id: f};
    final recent = payments.take(5).toList();

    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Recent Fee Collections',
      trailing: TextButton(
        onPressed: () => context.push(AppRoutes.adminFeePayments),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('View All'), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16)],
        ),
      ),
      childPadding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            const Divider(height: 1),
            _CollectionRow(payment: recent[i], fee: feeById[recent[i].feeId]),
          ],
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final FeePayment payment;
  final Fee? fee;

  const _CollectionRow({required this.payment, required this.fee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = switch (payment.status) {
      'approved' => ('Approved', FeeColors.paid),
      'rejected' => ('Rejected', FeeColors.pending),
      _ => ('Pending', FeeColors.partial),
    };
    final studentLabel = fee?.studentName ?? payment.studentAdmissionNumber ?? 'Unknown';
    final classLabel = fee?.className != null ? '${fee!.className} - ${fee!.section ?? ''}'.trim() : null;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final (method, methodIcon) = switch (payment.method.toLowerCase()) {
      'esewa' => ('eSewa', Icons.account_balance_wallet_outlined),
      'khalti' => ('Khalti', Icons.account_balance_wallet_outlined),
      'bank' || 'bank transfer' => ('Bank Transfer', Icons.account_balance_outlined),
      '' || 'cash' => ('Cash', Icons.payments_outlined),
      _ => (payment.method, Icons.payments_outlined),
    };

    return InkWell(
      onTap: () => context.push(AppRoutes.adminFeePayments),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person_outline_rounded, size: 20, color: context.readable(AppColors.primary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [
                      if (classLabel != null && classLabel.isNotEmpty) classLabel,
                      formatDisplayDate(payment.createdAt),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(methodIcon, size: 14, color: context.readable(AppColors.primary)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(method, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRs(payment.amount),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                AppStatusChip(label: statusLabel, color: statusColor),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
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
    final statusColor = switch (fee.status) {
      'paid' => FeeColors.paid,
      'partial' => FeeColors.partial,
      _ => FeeColors.pending,
    };
    final initial = studentLabel.isNotEmpty ? studentLabel[0].toUpperCase() : '?';
    return StaggeredEntrance(
      child: PressScale(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.16),
              foregroundColor: statusColor,
              child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            title: Text('${fee.title} — $studentLabel'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text('${fee.className ?? ''} ${fee.section ?? ''} · ${formatRs(fee.totalAmount)}'),
                  AppStatusChip(label: capitalize(fee.status), color: statusColor),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: FeeProgressBar(paid: fee.paidAmount, total: fee.totalAmount, color: statusColor),
                  ),
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
                  ListTile(
                    dense: true,
                    title: Text(inst.title),
                    subtitle: Text('Due ${inst.dueDate} · ${inst.status}'),
                    trailing: Text('Rs ${inst.amount.toStringAsFixed(0)}'),
                  )
              else
                ListTile(dense: true, title: const Text('Due date'), trailing: Text(fee.dueDate)),
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
          ),
        ),
      ),
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

  final succeeded = await runWithProgress(context, () => provider.deleteFee(fee.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete fee')));
  }
}

Future<void> _downloadExport(BuildContext context, FeeProvider provider, String? status) async {
  final bytes = await runWithProgress(context, () => provider.exportFees(status: status), message: 'Exporting fees…');
  if (bytes != null) {
    if (context.mounted) await saveBytesOrNotify(context, bytes, 'fees.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export fees')));
  }
}
