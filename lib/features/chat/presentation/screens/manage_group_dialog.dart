import 'package:flutter/material.dart';

import '../../data/models/group_conversation.dart';
import '../../../../shared/widgets/progress_overlay.dart';
import '../providers/chat_provider.dart';

/// Teacher: member add/remove, archive, delete
/// (`implementation_backlog.md` E10-F1-T5). "Add students" reuses the same
/// roster-preview call the create-group dialog uses (`previewRoster` for
/// this group's own class/section) rather than a new student-search
/// dependency — anyone in that roster not already a member can be added.
Future<void> showManageGroupDialog(BuildContext context, ChatProvider provider, GroupConversation group) async {
  await runWithProgress(context, () async {
    await provider.loadGroupMembers(group.id);
    await provider.loadRosterPreview(classId: group.classId, sectionId: group.sectionId);
  }, message: 'Loading group…');
  if (!context.mounted) return;

  final toAdd = <String>{};

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final nonMembers = provider.rosterPreview
            .where((s) => !provider.groupMembers.any((m) => m.id == s.id))
            .toList();

        return AlertDialog(
          title: Text('Manage "${group.name}"'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Members (${provider.groupMembers.length})', style: Theme.of(dialogContext).textTheme.titleSmall),
                Expanded(
                  child: ListView(
                    children: [
                      for (final member in provider.groupMembers)
                        ListTile(
                          dense: true,
                          title: Text(member.fullName),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove',
                            onPressed: () async {
                              await runWithProgress(
                                dialogContext,
                                () => provider.updateMembers(group.id, removeStudentIds: [member.id]),
                                message: 'Removing member…',
                              );
                              setDialogState(() {});
                            },
                          ),
                        ),
                      if (nonMembers.isNotEmpty) ...[
                        const Divider(),
                        Text('Add students', style: Theme.of(dialogContext).textTheme.titleSmall),
                        for (final student in nonMembers)
                          CheckboxListTile(
                            dense: true,
                            title: Text(student.fullName),
                            value: toAdd.contains(student.id),
                            onChanged: (checked) {
                              if (checked ?? false) {
                                toAdd.add(student.id);
                              } else {
                                toAdd.remove(student.id);
                              }
                              setDialogState(() {});
                            },
                          ),
                      ],
                    ],
                  ),
                ),
                if (provider.actionError != null)
                  Text(
                    provider.actionError!.message,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await _confirmArchiveOrDelete(dialogContext, action: 'Archive');
                if (confirmed != true) return;
                if (!dialogContext.mounted) return;
                final succeeded = await runWithProgress(
                  dialogContext,
                  () => provider.archiveGroup(group.id),
                  message: 'Archiving…',
                );
                if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Archive'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
              onPressed: () async {
                final confirmed = await _confirmArchiveOrDelete(dialogContext, action: 'Delete');
                if (confirmed != true) return;
                if (!dialogContext.mounted) return;
                final succeeded = await runWithProgress(
                  dialogContext,
                  () => provider.deleteGroup(group.id),
                  message: 'Deleting…',
                );
                if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
            if (toAdd.isNotEmpty)
              FilledButton(
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        await runWithProgress(
                          dialogContext,
                          () => provider.updateMembers(group.id, addStudentIds: toAdd.toList()),
                          message: 'Adding students…',
                        );
                        toAdd.clear();
                        setDialogState(() {});
                      },
                child: const Text('Add'),
              ),
          ],
        );
      },
    ),
  );
}

Future<bool?> _confirmArchiveOrDelete(BuildContext context, {required String action}) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text('$action this group?'),
    content: Text(
      action == 'Delete'
          ? 'This permanently deletes the group and all its messages. This cannot be undone.'
          : 'The group will no longer accept new messages. Members can still see the history.',
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(action)),
    ],
  ),
);
