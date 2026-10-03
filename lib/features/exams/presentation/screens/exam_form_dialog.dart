import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../admin_management/presentation/providers/academic_structure_provider.dart';
import '../../data/models/exam.dart';
import '../providers/exam_provider.dart';
import '../../../../shared/widgets/form_sheet.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _SubjectDraft {
  final titleController = TextEditingController();
  final fullMarksController = TextEditingController(text: '100');
  final passMarksController = TextEditingController(text: '40');
  DateTime date = DateTime.now().add(const Duration(days: 7));
}

/// Admin: Create Exam. Reuses the app-wide `AcademicStructureProvider`
/// singleton for class/section pickers, same pattern as
/// `assignment_form_dialog.dart`. No edit mode yet (`updateExam` exists in
/// the repository but nothing calls it) — creating covers the P1 scope,
/// editing a live exam's subject list is more form complexity than this
/// pass has room for; flagged as a known gap rather than silently dropped.
Future<void> showExamFormDialog(BuildContext context, ExamProvider provider) async {
  final academicProvider = context.read<AcademicStructureProvider>();
  if (academicProvider.classesStatus != LoadStatus.success) {
    await academicProvider.loadClasses();
  }
  if (!context.mounted) return;

  final titleController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? selectedClass;
  String? selectedSection;
  DateTime examDate = DateTime.now().add(const Duration(days: 7));
  final subjects = <_SubjectDraft>[_SubjectDraft()];

  await showFormSheet<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => FormSheet(
        title: const Text('Add Exam'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: [
                      for (final c in academicProvider.classes) DropdownMenuItem(value: c.name, child: Text(c.name)),
                    ],
                    validator: (value) => value == null ? 'Class is required' : null,
                    onChanged: (value) async {
                      selectedClass = value;
                      selectedSection = null;
                      final matching = academicProvider.classes.where((c) => c.name == value);
                      if (matching.isNotEmpty) await academicProvider.loadSections(matching.first.id);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: [
                      for (final s in academicProvider.sections) DropdownMenuItem(value: s.name, child: Text(s.name)),
                    ],
                    validator: (value) => value == null ? 'Section is required' : null,
                    onChanged: (value) {
                      selectedSection = value;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Exam date: ${_formatDate(examDate)}'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: examDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            examDate = picked;
                            setDialogState(() {});
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Align(alignment: Alignment.centerLeft, child: Text('Subjects', style: Theme.of(dialogContext).textTheme.titleSmall)),
                  for (final subject in subjects) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: subject.titleController,
                            decoration: const InputDecoration(labelText: 'Subject'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: subject.fullMarksController,
                            decoration: const InputDecoration(labelText: 'Full'),
                            keyboardType: TextInputType.number,
                            validator: (value) => (int.tryParse(value ?? '') == null) ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: subject.passMarksController,
                            decoration: const InputDecoration(labelText: 'Pass'),
                            keyboardType: TextInputType.number,
                            validator: (value) => (int.tryParse(value ?? '') == null) ? 'Invalid' : null,
                          ),
                        ),
                        if (subjects.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove subject',
                            onPressed: () {
                              subjects.remove(subject);
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
                      label: const Text('Add subject'),
                      onPressed: () {
                        subjects.add(_SubjectDraft());
                        setDialogState(() {});
                      },
                    ),
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
                    final succeeded = await provider.createExam(
                      title: titleController.text.trim(),
                      className: selectedClass!,
                      section: selectedSection,
                      examDate: _formatDate(examDate),
                      subjects: [
                        for (final s in subjects)
                          ExamSubject(
                            name: s.titleController.text.trim(),
                            fullMarks: int.parse(s.fullMarksController.text),
                            passMarks: int.parse(s.passMarksController.text),
                            examDate: _formatDate(s.date),
                          ),
                      ],
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
