import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../providers/my_payslips_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Teacher self-service (`implementation_backlog.md` E8-F2) — payslip list
/// with an inline breakdown per row, same "no separate detail screen"
/// pattern `ExamsListScreen` uses (the already-loaded `GET /payroll/my`
/// list has every field a detail view would need).
class MyPayslipsScreen extends StatefulWidget {
  const MyPayslipsScreen({super.key});

  @override
  State<MyPayslipsScreen> createState() => _MyPayslipsScreenState();
}

class _MyPayslipsScreenState extends State<MyPayslipsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<MyPayslipsProvider>();
    Future.microtask(() => provider.loadMyPayslips());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyPayslipsProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Payslips'),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading payslips...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMyPayslips()),
          LoadStatus.success =>
            provider.payslips.isEmpty
                ? const EmptyStateView(message: 'No payslips generated yet', icon: Icons.receipt_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.payslips.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => index == 0
                        ? _LatestPayHighlight(payslip: provider.payslips.first)
                        : _PayslipTile(payslip: provider.payslips[index - 1]),
                  ),
        },
      ),
    );
  }
}

class _LatestPayHighlight extends StatelessWidget {
  final Payroll payslip;

  const _LatestPayHighlight({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.3)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LATEST PAYSLIP • ${_monthNames[payslip.month].toUpperCase()} ${payslip.year}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Take-home Pay', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          Text(
            'Rs ${payslip.netSalary.toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Text(
                'Gross Rs ${payslip.grossSalary.toStringAsFixed(0)} · Deductions Rs ${payslip.totalDeductions.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayslipTile extends StatelessWidget {
  final Payroll payslip;

  const _PayslipTile({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final statusColor = payslip.status == 'paid' ? Colors.green : Colors.orange;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: statusColor.withValues(alpha: 0.14),
          foregroundColor: statusColor,
          child: const Icon(Icons.receipt_long_outlined, size: 20),
        ),
        title: Text('${_monthNames[payslip.month]} ${payslip.year}', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text('Net Rs ${payslip.netSalary.toStringAsFixed(0)}'),
              AppStatusChip(label: payslip.status[0].toUpperCase() + payslip.status.substring(1), color: statusColor),
            ],
          ),
        ),
        children: [
          ListTile(
            dense: true,
            title: const Text('Basic Salary'),
            trailing: Text('Rs ${payslip.basicSalary.toStringAsFixed(0)}'),
          ),
          ListTile(
            dense: true,
            title: const Text('Allowances'),
            trailing: Text('Rs ${payslip.totalAllowances.toStringAsFixed(0)}'),
          ),
          ListTile(
            dense: true,
            title: const Text('Gross Salary'),
            trailing: Text('Rs ${payslip.grossSalary.toStringAsFixed(0)}'),
          ),
          ListTile(
            dense: true,
            title: const Text('Deductions'),
            trailing: Text('Rs ${payslip.totalDeductions.toStringAsFixed(0)}'),
          ),
          ListTile(
            dense: true,
            title: Text('Net Salary', style: Theme.of(context).textTheme.titleSmall),
            trailing: Text('Rs ${payslip.netSalary.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleSmall),
          ),
          if (payslip.remarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Remarks: ${payslip.remarks}')),
            ),
        ],
      ),
    );
  }
}
