import 'package:flutter/material.dart';

import '../../../admin_management/data/models/teacher.dart';
import '../../data/models/payroll.dart';
import '../../data/models/staff_salary_config.dart';
import '../providers/payroll_provider.dart';

/// Admin: set/update a Teacher's salary config — must exist before a
/// payroll can be generated for them (`generatePayroll` 404s otherwise,
/// confirmed by reading `payrollController.js` directly). `setStaffSalary`
/// is an upsert keyed on `staffId` server-side, so this same dialog covers
/// both "set for the first time" and "update rates" — no separate edit
/// mode needed.
Future<void> showSalaryConfigDialog(BuildContext context, PayrollProvider provider, {StaffSalaryConfig? existing}) async {
  if (existing == null && provider.teacherOptions.isEmpty) {
    await provider.loadTeacherOptions();
  }
  if (!context.mounted) return;

  final basicController = TextEditingController(text: existing?.basicSalary.toStringAsFixed(0));
  final houseRentController = TextEditingController(text: existing?.allowances.houseRent.toStringAsFixed(0) ?? '0');
  final transportController = TextEditingController(text: existing?.allowances.transport.toStringAsFixed(0) ?? '0');
  final medicalController = TextEditingController(text: existing?.allowances.medical.toStringAsFixed(0) ?? '0');
  final pfRateController = TextEditingController(text: existing?.pfRate.toStringAsFixed(0) ?? '10');
  final taxRateController = TextEditingController(text: existing?.taxRate.toStringAsFixed(0) ?? '5');
  final workingDaysController = TextEditingController(text: existing?.workingDays.toString() ?? '26');
  final formKey = GlobalKey<FormState>();

  Teacher? selectedTeacher;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Set Salary Config' : 'Update Salary Config'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null)
                    Autocomplete<Teacher>(
                      displayStringForOption: (t) => '${t.fullName} (${t.employeeId})',
                      optionsBuilder: (value) {
                        if (value.text.isEmpty) return provider.teacherOptions;
                        final query = value.text.toLowerCase();
                        return provider.teacherOptions
                            .where((t) => t.fullName.toLowerCase().contains(query) || t.employeeId.toLowerCase().contains(query));
                      },
                      onSelected: (t) {
                        selectedTeacher = t;
                        setDialogState(() {});
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Teacher', hintText: 'Search by name or employee id'),
                        validator: (_) => selectedTeacher == null ? 'Pick a teacher' : null,
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Teacher: ${existing.staffName ?? existing.staffId}'),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: basicController,
                    decoration: const InputDecoration(labelText: 'Basic Salary (Rs)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (double.tryParse(value ?? '') == null) ? 'Invalid amount' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: houseRentController,
                          decoration: const InputDecoration(labelText: 'House Rent'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: transportController,
                          decoration: const InputDecoration(labelText: 'Transport'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: medicalController,
                          decoration: const InputDecoration(labelText: 'Medical'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pfRateController,
                          decoration: const InputDecoration(labelText: 'PF %'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: taxRateController,
                          decoration: const InputDecoration(labelText: 'Tax %'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: workingDaysController,
                          decoration: const InputDecoration(labelText: 'Working days'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  if (provider.configActionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.configActionError!.message,
                      style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSavingConfig
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = await provider.setStaffSalary(
                      staffId: existing?.staffId ?? selectedTeacher!.id,
                      basicSalary: double.parse(basicController.text),
                      allowances: PayrollAllowances(
                        houseRent: double.tryParse(houseRentController.text) ?? 0,
                        transport: double.tryParse(transportController.text) ?? 0,
                        medical: double.tryParse(medicalController.text) ?? 0,
                        other: 0,
                      ),
                      pfRate: double.tryParse(pfRateController.text),
                      taxRate: double.tryParse(taxRateController.text),
                      workingDays: int.tryParse(workingDaysController.text),
                    );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSavingConfig
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
