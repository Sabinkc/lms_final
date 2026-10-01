import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/class_section.dart';
import '../providers/academic_structure_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: className == null ? 'Sections' : 'Sections — $className'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showSectionFormDialog(context, provider, classId: widget.classId),
          tooltip: 'Add Section',
          child: const Icon(Icons.add),
        ),
        body: SectionsPanel(classId: widget.classId),
      ),
    );
  }
}

/// The section list for one class, without its own `Scaffold` — used both
/// by [SectionsListScreen] and as the Sections tab of `ClassDetailScreen`.
/// Loading is the caller's job (`AcademicStructureProvider.loadSections`).
class SectionsPanel extends StatelessWidget {
  final String classId;

  /// Embedded inside another scroll view (Class Details), the list sizes to
  /// its content instead of scrolling on its own.
  final bool embedded;

  const SectionsPanel({super.key, required this.classId, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicStructureProvider>();
    return switch (provider.sectionsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading sections...'),
      LoadStatus.error => ErrorView(error: provider.sectionsError!, onRetry: () => provider.loadSections(classId)),
      LoadStatus.success =>
        provider.sections.isEmpty
            ? EmptyStateView(
                message: 'No sections set up yet',
                icon: Icons.groups_outlined,
                actionLabel: 'Add Section',
                onAction: () => showSectionFormDialog(context, provider, classId: classId),
              )
            : ListView.separated(
                shrinkWrap: embedded,
                physics: embedded ? const NeverScrollableScrollPhysics() : null,
                padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(16),
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
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.groups_outlined, color: accent, size: 20),
                      ),
                      title: Text(section.name, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text('${section.studentCount} student${section.studentCount == 1 ? '' : 's'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () =>
                                showSectionFormDialog(context, provider, classId: classId, existing: section),
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
    };
  }
}

Future<void> showSectionFormDialog(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.sectionActionError?.message ?? 'Failed to delete section')));
  }
}
