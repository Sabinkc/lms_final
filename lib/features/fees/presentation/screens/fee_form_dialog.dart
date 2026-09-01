import 'package:flutter/material.dart';

import '../../../admin_management/data/models/student.dart';
import '../../data/models/fee.dart';
import '../../data/repositories/fee_repository.dart';
import '../providers/fee_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _InstallmentDraft {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));
}

/// Admin: Add/Edit Fee. Create mode picks a Student (`createFee` requires
/// `studentId` — this is a per-student fee, not per-class, see
/// `FeeRepository`'s doc comment) via a built-in `Autocomplete`, no new
/// dependency needed. Edit mode can't change the student, and per
/// `feeController.js`'s `updateFee` (confirmed by reading it directly)
/// `totalAmount`/`dueDate` are silently ignored server-side once
/// `isInstallment` is true — those two fields are disabled in that case
/// rather than submitting a change the backend would quietly drop.
Future<void> showFeeFormDialog(BuildContext context, FeeProvider provider, {Fee? existing}) async {
  if (existing == null && provider.studentOptions.isEmpty) {
    await provider.loadStudentOptions();
  }
  if (!context.mounted) return;

  final titleController = TextEditingController(text: existing?.title);
  final descriptionController = TextEditingController(text: existing?.description);
  final totalAmountController = TextEditingController(text: existing?.totalAmount.toStringAsFixed(0));
  final discountController = TextEditingController(text: existing?.discountPercent.toStringAsFixed(0) ?? '0');
  final formKey = GlobalKey<FormState>();

  Student? selectedStudent;
  bool isInstallment = existing?.isInstallment ?? false;
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));
  final installments = <_InstallmentDraft>[_InstallmentDraft()];

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Fee' : 'Edit Fee'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null) ...[
                    Autocomplete<Student>(
                      displayStringForOption: (s) => '${s.fullName} (${s.admissionNumber})',
                      optionsBuilder: (value) {
                        if (value.text.isEmpty) return provider.studentOptions;
                        final query = value.text.toLowerCase();
                        return provider.studentOptions.where(
                          (s) => s.fullName.toLowerCase().contains(query) || s.admissionNumber.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (s) {
                        selectedStudent = s;
                        setDialogState(() {});
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Student', hintText: 'Search by name or admission no.'),
                        validator: (_) => selectedStudent == null ? 'Pick a student' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Student: ${existing.studentName ?? existing.admissionNumber ?? existing.studentId}'),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                    autofocus: existing != null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: totalAmountController,
                          enabled: !(existing?.isInstallment ?? false),
                          decoration: const InputDecoration(labelText: 'Total Amount (Rs)'),
                          keyboardType: TextInputType.number,
                          validator: (value) => (double.tryParse(value ?? '') == null) ? 'Invalid amount' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: discountController,
                          enabled: existing == null,
                          decoration: const InputDecoration(labelText: 'Discount %'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Installment plan'),
                      value: isInstallment,
                      onChanged: (value) {
                        isInstallment = value;
                        setDialogState(() {});
                      },
                    ),
                    if (!isInstallment)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Due: ${_formatDate(dueDate)}'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                dueDate = picked;
                                setDialogState(() {});
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      )
                    else ...[
                      const Divider(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Installments', style: Theme.of(dialogContext).textTheme.titleSmall),
                      ),
                      for (final inst in installments) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: inst.titleController,
                                decoration: const InputDecoration(labelText: 'Label (optional)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: inst.amountController,
                                decoration: const InputDecoration(labelText: 'Amount'),
                                keyboardType: TextInputType.number,
                                validator: (value) => (double.tryParse(value ?? '') == null) ? 'Invalid' : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_month_outlined),
                              tooltip: _formatDate(inst.dueDate),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: inst.dueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                if (picked != null) {
                                  inst.dueDate = picked;
                                  setDialogState(() {});
                                }
                              },
                            ),
                            if (installments.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove installment',
                                onPressed: () {
                                  installments.remove(inst);
                                  setDialogState(() {});
                                },
                              ),
                          ],
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add installment'),
                          onPressed: () {
                            installments.add(_InstallmentDraft());
                            setDialogState(() {});
                          },
                        ),
                      ),
                    ],
                  ] else if (existing.isInstallment)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Installments can\'t be edited here — delete and recreate the fee if the plan is wrong.',
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Due: ${_formatDate(dueDate)}'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (picked != null) {
                              dueDate = picked;
                              setDialogState(() {});
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  if (provider.actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.actionError!.message,
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
            onPressed: provider.isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = existing == null
                        ? await provider.createFee(
                            studentId: selectedStudent!.id,
                            title: titleController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            totalAmount: double.parse(totalAmountController.text),
                            discountPercent: double.tryParse(discountController.text) ?? 0,
                            dueDate: isInstallment ? null : _formatDate(dueDate),
                            isInstallment: isInstallment,
                            installments: isInstallment
                                ? [
                                    for (final i in installments)
                                      FeeInstallmentInput(
                                        title: i.titleController.text.trim().isEmpty ? null : i.titleController.text.trim(),
                                        amount: double.parse(i.amountController.text),
                                        dueDate: _formatDate(i.dueDate),
                                      ),
                                  ]
                                : null,
                          )
                        : await provider.updateFee(
                            id: existing.id,
                            title: titleController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            totalAmount: existing.isInstallment ? null : double.parse(totalAmountController.text),
                            dueDate: existing.isInstallment ? null : _formatDate(dueDate),
                          );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSaving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
