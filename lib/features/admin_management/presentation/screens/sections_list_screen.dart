import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/class_section.dart';
import '../providers/academic_structure_provider.dart';

/// docs/screens.md "Manage Classes / Sections / Subjects" — the Sections
/// half, scoped to one [classId] (reached by tapping a class in
/// [ClassesListScreen]).
class SectionsListScreen extends StatefulWidget {
  final String classId;

  const SectionsListScreen({super.key, required this.classId});

  @override
  State<SectionsListScreen> createState() => _SectionsListScreenState();
}

class _SectionsListScreenState extends State<SectionsListScreen> {
  @override
  void initState() {
    super.initState();
    // See ClassesListScreen.initState's comment: deferred to a microtask so
    // `loadSections()`'s synchronous-before-first-`await` `notifyListeners()`
    // doesn't fire mid-build.
    final provider = context.read<AcademicStructureProvider>();
    Future.microtask(() => provider.loadSections(widget.classId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicStructureProvider>();
    final matchingClasses = provider.classes.where((c) => c.id == widget.classId);
    final className = matchingClasses.isEmpty ? null : matchingClasses.first.name;

    return Scaffold(
      appBar: AppBar(title: Text(className == null ? 'Sections' : 'Sections — $className')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSectionFormDialog(context, provider, classId: widget.classId),
        tooltip: 'Add Section',
        child: const Icon(Icons.add),
      ),
      body: switch (provider.sectionsStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading sections...'),
        LoadStatus.error => ErrorView(
            error: provider.sectionsError!,
            onRetry: () => provider.loadSections(widget.classId),
          ),
        LoadStatus.success => provider.sections.isEmpty
            ? EmptyStateView(
                message: 'No sections set up yet',
                icon: Icons.groups_outlined,
                actionLabel: 'Add Section',
                onAction: () => _showSectionFormDialog(context, provider, classId: widget.classId),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.sections.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final section = provider.sections[index];
                  final accent = Theme.of(context).colorScheme.primary;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: accent.withValues(alpha: 0.14),
                        child: Icon(Icons.groups_outlined, color: accent, size: 20),
                      ),
                      title: Text(section.name, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text('${section.studentCount} student${section.studentCount == 1 ? '' : 's'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _showSectionFormDialog(context, provider, classId: widget.classId, existing: section),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDeleteSection(context, provider, section),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      },
    );
  }
}

Future<void> _showSectionFormDialog(
  BuildContext context,
  AcademicStructureProvider provider, {
  required String classId,
  ClassSection? existing,
}) async {
  final nameController = TextEditingController(text: existing?.name);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Section' : 'Edit Section'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                autofocus: true,
              ),
              if (provider.sectionActionError != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.sectionActionError!.message,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSavingSection
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = existing == null
                        ? await provider.createSection(classId: classId, name: nameController.text.trim())
                        : await provider.updateSection(id: existing.id, name: nameController.text.trim());
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSavingSection
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeleteSection(
  BuildContext context,
  AcademicStructureProvider provider,
  ClassSection section,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete section?'),
      content: Text(
        'This will permanently delete "${section.name}". '
        '${section.studentCount > 0 ? 'Its ${section.studentCount} student(s) will be unassigned, not deleted. ' : ''}'
        'This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final succeeded = await provider.deleteSection(section.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.sectionActionError?.message ?? 'Failed to delete section')),
    );
  }
}
