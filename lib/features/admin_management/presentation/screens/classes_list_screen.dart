import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/academic_class.dart';
import '../providers/academic_structure_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/class_badge.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// docs/screens.md "Manage Classes / Sections / Subjects" — the Classes
/// half; tapping a class drills into [SectionsListScreen] for its Sections.
///
/// Restyled 2026-09-30 to a reference the user supplied (`LMS UI/WhatsApp
/// Image ... 3.47.04 PM.jpeg`): "Add Class" in the app bar, colorful
/// per-class badges, and "N Students • N Sections" under each name. Student
/// counts come from `StudentProvider`'s full list (grouped by class name —
/// the Students screen reloads it on open, so loading it here is safe);
/// section counts from the `sections` array `GET /classes` already embeds.
/// Not carried over: the reference's per-grade filter chips and filter
/// button — with one row per class, a chip per class would just duplicate
/// the list, and search already narrows it. Edit/Delete moved into a ⋮
/// menu so each row matches the reference's clean single-chevron look.
class ClassesListScreen extends StatefulWidget {
  const ClassesListScreen({super.key});

  @override
  State<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Deferred to a microtask: `loadClasses()` calls `notifyListeners()`
    // before its first `await` (it sets loading state synchronously), and
    // calling that synchronously from `initState()` — still inside the
    // build phase — trips provider's "markNeedsBuild during build" guard.
    // The Retry button's own call to `loadClasses()` doesn't need this;
    // that one fires from a tap, safely after the build phase has ended.
    final provider = context.read<AcademicStructureProvider>();
    final students = context.read<StudentProvider>();
    Future.microtask(() {
      provider.loadClasses();
      students.loadStudents();
    });
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AcademicStructureProvider>().loadClasses(silent: true),
      context.read<StudentProvider>().loadStudents(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicStructureProvider>();
    final studentProvider = context.watch<StudentProvider>();
    // Counts only once the full (unfiltered) list is in — otherwise a
    // class-filtered list from the Students screen would undercount.
    final studentCounts = studentProvider.status == LoadStatus.success && studentProvider.classFilter == null
        ? studentProvider.students.fold<Map<String, int>>(
            {},
            (counts, s) => counts..update(s.className, (n) => n + 1, ifAbsent: () => 1),
          )
        : null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Classes',
          actions: [
            TextButton.icon(
              onPressed: () => showClassFormDialog(context, provider),
              icon: const Icon(Icons.add_circle, size: 22),
              label: const Text('Add Class'),
              style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.classesStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading classes...'),
            LoadStatus.error => ErrorView(error: provider.classesError!, onRetry: () => provider.loadClasses()),
            LoadStatus.success =>
              provider.classes.isEmpty
                  ? EmptyStateView(
                      message: 'No classes set up yet',
                      icon: Icons.school_outlined,
                      actionLabel: 'Add Class',
                      onAction: () => showClassFormDialog(context, provider),
                    )
                  : _ClassesList(
                      searchController: _searchController,
                      classes: provider.classes
                          .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query))
                          .toList(),
                      studentCounts: studentCounts,
                      onTap: (academicClass) => context.push(AppRoutes.adminClassDetail(academicClass.id)),
                      onEdit: (academicClass) => showClassFormDialog(context, provider, existing: academicClass),
                      onDelete: (academicClass) => confirmDeleteClass(context, provider, academicClass),
                    ),
          },
        ),
      ),
    );
  }
}

class _ClassesList extends StatelessWidget {
  final TextEditingController searchController;
  final List<AcademicClass> classes;
  final Map<String, int>? studentCounts;
  final ValueChanged<AcademicClass> onTap;
  final ValueChanged<AcademicClass> onEdit;
  final ValueChanged<AcademicClass> onDelete;

  const _ClassesList({
    required this.searchController,
    required this.classes,
    required this.studentCounts,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search classes...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: classes.isEmpty
              ? const EmptyStateView(message: 'No classes match your search')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: classes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final academicClass = classes[index];
                    return _ClassCard(
                      academicClass: academicClass,
                      studentCount: studentCounts == null ? null : (studentCounts![academicClass.name] ?? 0),
                      onTap: () => onTap(academicClass),
                      onEdit: () => onEdit(academicClass),
                      onDelete: () => onDelete(academicClass),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final AcademicClass academicClass;
  final int? studentCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.academicClass,
    required this.studentCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final sectionCount = academicClass.sectionCount;
    final isInactive = academicClass.status.toLowerCase() != 'active';

    final meta = <Widget>[
      if (studentCount != null)
        _Meta(icon: Icons.person_rounded, label: _plural(studentCount!, 'Student'), style: muted),
      if (sectionCount != null)
        _Meta(icon: Icons.groups_rounded, label: _plural(sectionCount, 'Section'), style: muted),
    ];

    return StaggeredEntrance(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                ClassBadge(name: academicClass.name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              academicClass.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (isInactive) ...[
                            const SizedBox(width: 6),
                            AppStatusChip(label: academicClass.status, color: scheme.error),
                          ],
                        ],
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            for (var i = 0; i < meta.length; i++) ...[if (i > 0) Text('•', style: muted), meta[i]],
                          ],
                        ),
                      ] else if (academicClass.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(academicClass.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Class actions',
                  icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                  onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? style;

  const _Meta({required this.icon, required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: style?.color),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}

String _plural(int n, String noun) => '$n ${n == 1 ? noun : '${noun}s'}';

Future<void> showClassFormDialog(
  BuildContext context,
  AcademicStructureProvider provider, {
  AcademicClass? existing,
}) async {
  final nameController = TextEditingController(text: existing?.name);
  final descriptionController = TextEditingController(text: existing?.description);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Class' : 'Edit Class'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              if (provider.classActionError != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.classActionError!.message,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSavingClass
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = existing == null
                        ? await provider.createClass(
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                          )
                        : await provider.updateClass(
                            id: existing.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                          );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSavingClass
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// Returns whether the class was actually deleted.
Future<bool> confirmDeleteClass(
  BuildContext context,
  AcademicStructureProvider provider,
  AcademicClass academicClass,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete class?'),
      content: Text('This will permanently delete "${academicClass.name}". This cannot be undone.'),
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

  if (confirmed != true || !context.mounted) return false;

  final succeeded = await runWithProgress(context, () => provider.deleteClass(academicClass.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.classActionError?.message ?? 'Failed to delete class')));
  }
  return succeeded;
}
