import 'package:flutter/material.dart';

import '../../data/models/staff_salary_config.dart';
import '../providers/payroll_provider.dart';
import '../../../../shared/widgets/form_sheet.dart';

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

/// Admin: generate a single payroll for one staff member with a salary
/// config already set (`generatePayroll` 404s otherwise — this dialog only
/// offers staff already in [PayrollProvider.configs] so that can't happen
/// from here). For "generate for everyone at once" see
/// `PayrollScreen`'s bulk-generate action, which calls
/// `PayrollProvider.generateBulkPayroll` directly without this per-staff
/// form.
Future<void> showGeneratePayrollDialog(BuildContext context, PayrollProvider provider) async {
  if (provider.configs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Set a salary config for at least one teacher first')),
    );
    return;
  }

  final now = DateTime.now();
  final absentDaysController = TextEditingController(text: '0');
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  StaffSalaryConfig? selectedConfig;
  int month = now.month;
  int year = now.year;

  await showFormSheet<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => FormSheet(
        title: const Text('Generate Payroll'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StaffSalaryConfig>(
                initialValue: selectedConfig,
                decoration: const InputDecoration(labelText: 'Teacher'),
                items: [
                  for (final c in provider.configs)
                    DropdownMenuItem(value: c, child: Text(c.staffName ?? c.staffId)),
                ],
                validator: (value) => value == null ? 'Pick a teacher' : null,
                onChanged: (value) {
                  selectedConfig = value;
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: month,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(_monthNames[m]))],
                      onChanged: (value) {
                        if (value != null) {
                          month = value;
                          setDialogState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: year,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: [for (var y = now.year - 1; y <= now.year + 1; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                      onChanged: (value) {
                        if (value != null) {
                          year = value;
                          setDialogState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: absentDaysController,
                decoration: const InputDecoration(labelText: 'Absent days this month'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (optional)'),
              ),
              if (provider.generateError != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.generateError!.message,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isGenerating
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = await provider.generatePayroll(
                      staffId: selectedConfig!.staffId,
                      month: month,
                      year: year,
                      absentDays: int.tryParse(absentDaysController.text) ?? 0,
                      remarks: remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
                    );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isGenerating
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Generate'),
          ),
        ],
      ),
    ),
  );
}
