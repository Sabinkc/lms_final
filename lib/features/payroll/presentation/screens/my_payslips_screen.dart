import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/payroll.dart';
import '../providers/my_payslips_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('My Payslips')),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading payslips...'),
        LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadMyPayslips()),
        LoadStatus.success => provider.payslips.isEmpty
            ? const EmptyStateView(message: 'No payslips generated yet', icon: Icons.receipt_outlined)
            : ListView.builder(
                itemCount: provider.payslips.length,
                itemBuilder: (context, index) => _PayslipTile(payslip: provider.payslips[index]),
              ),
      },
    );
  }
}

class _PayslipTile extends StatelessWidget {
  final Payroll payslip;

  const _PayslipTile({required this.payslip});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('${_monthNames[payslip.month]} ${payslip.year}'),
      subtitle: Text('Net Rs ${payslip.netSalary.toStringAsFixed(0)} · ${payslip.status[0].toUpperCase()}${payslip.status.substring(1)}'),
      children: [
        ListTile(dense: true, title: const Text('Basic Salary'), trailing: Text('Rs ${payslip.basicSalary.toStringAsFixed(0)}')),
        ListTile(
          dense: true,
          title: const Text('Allowances'),
          trailing: Text('Rs ${payslip.totalAllowances.toStringAsFixed(0)}'),
        ),
        ListTile(dense: true, title: const Text('Gross Salary'), trailing: Text('Rs ${payslip.grossSalary.toStringAsFixed(0)}')),
        ListTile(
          dense: true,
          title: const Text('Deductions'),
          trailing: Text('Rs ${payslip.totalDeductions.toStringAsFixed(0)}'),
        ),
        ListTile(
          dense: true,
          title: Text('Net Salary', style: Theme.of(context).textTheme.titleSmall),
          trailing: Text(
            'Rs ${payslip.netSalary.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (payslip.remarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Remarks: ${payslip.remarks}')),
          ),
      ],
    );
  }
}
