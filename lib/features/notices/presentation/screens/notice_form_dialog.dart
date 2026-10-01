import 'package:flutter/material.dart';

import '../../data/models/notice.dart';
import '../providers/notice_provider.dart';

const _audiences = ['all', 'students', 'teachers', 'parents', 'admins'];

String _audienceLabel(String a) => a == 'all' ? 'Everyone' : a[0].toUpperCase() + a.substring(1);

/// Admin: Create/Edit Notice.
Future<void> showNoticeFormDialog(
  BuildContext context,
  NoticeProvider provider, {
  Notice? existing,
}) async {
  final titleController = TextEditingController(text: existing?.title);
  final descriptionController = TextEditingController(text: existing?.description);
  final formKey = GlobalKey<FormState>();

  String audience = existing?.audience ?? 'all';
  bool isImportant = existing?.isImportant ?? false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Notice' : 'Edit Notice'),
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
                    maxLines: 4,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: audience,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: [
                      for (final a in _audiences) DropdownMenuItem(value: a, child: Text(_audienceLabel(a))),
                    ],
                    onChanged: (value) {
                      audience = value!;
                      setDialogState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Important'),
                    value: isImportant,
                    onChanged: (value) {
                      isImportant = value ?? false;
                      setDialogState(() {});
                    },
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
                        ? await provider.createNotice(
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            audience: audience,
                            isImportant: isImportant,
                          )
                        : await provider.updateNotice(
                            id: existing.id,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            audience: audience,
                            isImportant: isImportant,
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
