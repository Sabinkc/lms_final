import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/subject_icon.dart';
import '../../../../shared/widgets/status_chip.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/department.dart';
import '../../data/models/teacher.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/department_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// Admin: Manage Departments (`docs/production_roadmap.md` Phase L2,
/// `implementation_backlog.md` E17) — same list/create/edit/delete shape as
/// [ClassesListScreen], the closest existing precedent for a flat Admin CRUD
/// screen.
class DepartmentsListScreen extends StatefulWidget {
  const DepartmentsListScreen({super.key});

  @override
  State<DepartmentsListScreen> createState() => _DepartmentsListScreenState();
}

class _DepartmentsListScreenState extends State<DepartmentsListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<DepartmentProvider>();
    Future.microtask(() {
      provider.loadDepartments();
      provider.loadOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DepartmentProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Departments'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDepartmentFormDialog(context, provider),
          tooltip: 'Add Department',
          child: const Icon(Icons.add),
        ),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading departments...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadDepartments()),
          LoadStatus.success =>
            provider.departments.isEmpty
                ? EmptyStateView(
                    message: 'No departments set up yet',
                    icon: Icons.apartment_outlined,
                    actionLabel: 'Add Department',
                    onAction: () => _showDepartmentFormDialog(context, provider),
                  )
                : _DepartmentsList(
                    departments: provider.departments,
                    onEdit: (department) => _showDepartmentFormDialog(context, provider, existing: department),
                    onDelete: (department) => _confirmDeleteDepartment(context, provider, department),
                  ),
        },
      ),
    );
  }
}

class _DepartmentsList extends StatefulWidget {
  final List<Department> departments;
  final ValueChanged<Department> onEdit;
  final ValueChanged<Department> onDelete;

  const _DepartmentsList({required this.departments, required this.onEdit, required this.onDelete});

  @override
  State<_DepartmentsList> createState() => _DepartmentsListState();
}

class _DepartmentsListState extends State<_DepartmentsList> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final visible = widget.departments
        .where(
          (d) =>
              query.isEmpty ||
              d.name.toLowerCase().contains(query) ||
              (d.headOfDepartmentName?.toLowerCase().contains(query) ?? false),
        )
        .toList();
    final heads = widget.departments.where((d) => d.headOfDepartmentName != null).length;
    final classes = {for (final d in widget.departments) ...d.classes};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search department or head',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            AppStatusPill(
              label: '${widget.departments.length} department${widget.departments.length == 1 ? '' : 's'}',
              icon: Icons.apartment_outlined,
              color: AppColors.primary,
            ),
            AppStatusPill(label: '$heads with a head', icon: Icons.person_outline, color: AppColors.info),
            AppStatusPill(
              label: '${classes.length} class${classes.length == 1 ? '' : 'es'} covered',
              icon: Icons.class_outlined,
              color: const Color(0xFFEA580C),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: EmptyStateView(message: 'No departments match your search', icon: Icons.search_off),
          ),
        for (final department in visible) ...[
          _DepartmentCard(
            department: department,
            onEdit: () => widget.onEdit(department),
            onDelete: () => widget.onDelete(department),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentCard({required this.department, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(subjectIcon(department.name), color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(department.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            department.headOfDepartmentName != null
                                ? Icons.verified_user_outlined
                                : Icons.person_off_outlined,
                            size: 14,
                            color: department.headOfDepartmentName != null ? AppColors.primary : muted?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              department.headOfDepartmentName != null
                                  ? 'Head: ${department.headOfDepartmentName}'
                                  : 'No head assigned',
                              style: muted,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1)),
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ],
            ),
            if (department.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(department.description, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (department.classes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final className in department.classes) AppStatusPill(label: className, color: AppColors.info),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showDepartmentFormDialog(
  BuildContext context,
  DepartmentProvider provider, {
  Department? existing,
}) async {
  final nameController = TextEditingController(text: existing?.name);
  final descriptionController = TextEditingController(text: existing?.description);
  final formKey = GlobalKey<FormState>();

  Teacher? selectedHead;
  if (existing?.headOfDepartmentId != null) {
    for (final t in provider.teacherOptions) {
      if (t.id == existing!.headOfDepartmentId) {
        selectedHead = t;
        break;
      }
    }
  }
  final selectedClasses = {...?existing?.classes};

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Department' : 'Edit Department'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Autocomplete<Teacher>(
                  displayStringForOption: (t) => '${t.fullName} (${t.employeeId})',
                  initialValue: TextEditingValue(
                    text: selectedHead == null ? '' : '${selectedHead!.fullName} (${selectedHead!.employeeId})',
                  ),
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return provider.teacherOptions;
                    final query = value.text.toLowerCase();
                    return provider.teacherOptions.where((t) => t.fullName.toLowerCase().contains(query));
                  },
                  onSelected: (t) {
                    selectedHead = t;
                    setDialogState(() {});
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Head of Department (optional)'),
                  ),
                ),
                if (selectedHead != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setDialogState(() => selectedHead = null),
                      child: const Text('Clear head of department'),
                    ),
                  ),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Classes')),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final academicClass in provider.classOptions)
                      FilterChip(
                        label: Text(academicClass.name),
                        selected: selectedClasses.contains(academicClass.name),
                        onSelected: (isSelected) => setDialogState(() {
                          if (isSelected) {
                            selectedClasses.add(academicClass.name);
                          } else {
                            selectedClasses.remove(academicClass.name);
                          }
                        }),
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
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = existing == null
                        ? await provider.createDepartment(
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            headOfDepartmentId: selectedHead?.id,
                            classes: selectedClasses.toList(),
                          )
                        : await provider.updateDepartment(
                            id: existing.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            headOfDepartmentId: selectedHead?.id,
                            classes: selectedClasses.toList(),
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

Future<void> _confirmDeleteDepartment(BuildContext context, DepartmentProvider provider, Department department) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete department?'),
      content: Text('This will permanently delete "${department.name}". This cannot be undone.'),
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

  final succeeded = await provider.deleteDepartment(department.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete department')));
  }
}
