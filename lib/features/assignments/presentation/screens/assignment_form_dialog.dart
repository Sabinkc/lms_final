import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../attendance/data/models/teacher_section.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../data/models/assignment.dart';
import '../providers/assignment_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Teacher: Create/Edit Assignment. Create-mode class/section pickers are
/// sourced from `AttendanceRepository.getMySections()` (`GET
/// /api/sections/my/teacher`) rather than `AcademicStructureProvider`'s
/// `GET /api/classes` — that endpoint is `protectAdmin`-only and 401s for a
/// Teacher token, which silently left this dropdown empty for the one role
/// that actually uses this form. `getMySections` is Teacher-eligible
/// (`eitherAuth`) and already returns every active section with its class
/// name populated, so class/section names are derived from one fetch with
/// no separate per-class section lookup needed. Submits plain-text names,
/// not ids (see `AssignmentRepository.createAssignment`'s doc comment for
/// why: the `sectionId` path gates on section-teacher assignment that Phase
/// B never populates). Class/section are shown read-only in edit mode — the
/// underlying `updateAssignment` repository call intentionally doesn't
/// expose changing them, since re-picking a class/section after creation
/// isn't a case this form needs to support yet.
Future<void> showAssignmentFormDialog(
  BuildContext context,
  AssignmentProvider provider, {
  Assignment? existing,
}) async {
  List<TeacherSection> teacherSections = const [];
  String? loadError;
  if (existing == null) {
    final result = await sl<AttendanceRepository>().getMySections();
    result.when(
      success: (sections) => teacherSections = sections,
      failure: (error) => loadError = error.message,
    );
  }
  if (!context.mounted) return;

  final classNames = {for (final s in teacherSections) s.className}.toList()..sort();

  final titleController = TextEditingController(text: existing?.title);
  final descriptionController = TextEditingController(text: existing?.description);
  final subjectController = TextEditingController(text: existing?.subject);
  final formKey = GlobalKey<FormState>();

  String? selectedClass = existing?.className;
  String? selectedSection = existing?.section;
  DateTime dueDate = existing != null && existing.dueDate.isNotEmpty
      ? DateTime.tryParse(existing.dueDate) ?? DateTime.now().add(const Duration(days: 7))
      : DateTime.now().add(const Duration(days: 7));

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Assignment' : 'Edit Assignment'),
        content: SizedBox(
          width: 400,
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
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Subject is required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (existing != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Class ${existing.className} · Section ${existing.section}'),
                    ),
                  ] else ...[
                    if (loadError != null) ...[
                      Text(
                        'Could not load your classes: $loadError',
                        style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: [
                        for (final name in classNames) DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      validator: (value) => value == null ? 'Class is required' : null,
                      onChanged: (value) {
                        selectedClass = value;
                        selectedSection = null;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: [
                        for (final s in teacherSections)
                          if (s.className == selectedClass) DropdownMenuItem(value: s.name, child: Text(s.name)),
                      ],
                      validator: (value) => value == null ? 'Section is required' : null,
                      onChanged: (value) {
                        selectedSection = value;
                        setDialogState(() {});
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
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
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        ? await provider.createAssignment(
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            className: selectedClass!,
                            section: selectedSection!,
                            subject: subjectController.text.trim(),
                            dueDate: _formatDate(dueDate),
                          )
                        : await provider.updateAssignment(
                            id: existing.id,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            subject: subjectController.text.trim(),
                            dueDate: _formatDate(dueDate),
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
