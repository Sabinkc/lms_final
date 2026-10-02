import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/status_chip.dart';

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
                  final theme = Theme.of(context);
                  final active = section.status.isEmpty || section.status.toLowerCase() == 'active';
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(
                              section.name.isEmpty ? '?' : section.name.substring(0, section.name.length.clamp(0, 2)),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Section ${section.name}',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    AppStatusPill(
                                      label: '${section.studentCount} student${section.studentCount == 1 ? '' : 's'}',
                                      icon: Icons.groups_outlined,
                                      color: AppColors.info,
                                    ),
                                    if (section.teacherIds.isNotEmpty)
                                      AppStatusPill(
                                        label:
                                            '${section.teacherIds.length} teacher${section.teacherIds.length == 1 ? '' : 's'}',
                                        icon: Icons.co_present_outlined,
                                        color: AppColors.primary,
                                      ),
                                    if (!active)
                                      AppStatusPill(label: section.status, color: theme.colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                showSectionFormDialog(context, provider, classId: classId, existing: section),
                          ),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                            ),
                            icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
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

  final succeeded = await runWithProgress(context, () => provider.deleteSection(section.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.sectionActionError?.message ?? 'Failed to delete section')));
  }
}
