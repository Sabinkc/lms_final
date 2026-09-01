import 'package:flutter/material.dart';

import '../../data/models/eligible_target.dart';
import '../providers/chat_provider.dart';

/// Teacher: create a group conversation for a class/section they're
/// actually assigned to (`GET /group-chats/eligible-targets` — the one
/// place this backend enforces "assigned sections only" for a Teacher,
/// unlike Attendance/Assignments/Exams which let a Teacher act on any
/// section in the school). Leaving Section on "Whole Class" auto-enrolls
/// every student in that class by name match, matching
/// `createGroupConversation`'s own fallback when no `sectionId` is sent.
Future<void> showCreateGroupDialog(BuildContext context, ChatProvider provider) async {
  await provider.loadEligibleTargets();
  if (!context.mounted) return;

  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  EligibleTarget? selectedClass;
  EligibleSection? selectedSection;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('New Group'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<EligibleTarget>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    for (final target in provider.eligibleTargets)
                      DropdownMenuItem(value: target, child: Text(target.className)),
                  ],
                  validator: (value) => value == null ? 'Pick a class' : null,
                  onChanged: (value) {
                    selectedClass = value;
                    selectedSection = null;
                    provider.loadRosterPreview(classId: value!.classId);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                if (selectedClass != null)
                  DropdownButtonFormField<EligibleSection?>(
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Whole Class')),
                      for (final section in selectedClass!.sections)
                        DropdownMenuItem(value: section, child: Text(section.name)),
                    ],
                    onChanged: (value) {
                      selectedSection = value;
                      provider.loadRosterPreview(classId: selectedClass!.classId, sectionId: value?.id);
                      setDialogState(() {});
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Group name (optional)'),
                ),
                if (selectedClass != null) ...[
                  const SizedBox(height: 12),
                  Text('${provider.rosterPreview.length} student(s) will be added'),
                ],
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
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = await provider.createGroup(
                      classId: selectedClass!.classId,
                      sectionId: selectedSection?.id,
                      name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                    );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSaving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
