import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/department.dart';
import '../../data/models/teacher.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/department_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentFormDialog(context, provider),
        tooltip: 'Add Department',
        child: const Icon(Icons.add),
      ),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading departments...'),
        LoadStatus.error => ErrorView(
            error: provider.error!,
            onRetry: () => provider.loadDepartments(),
          ),
        LoadStatus.success => provider.departments.isEmpty
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
    );
  }
}

class _DepartmentsList extends StatelessWidget {
  final List<Department> departments;
  final ValueChanged<Department> onEdit;
  final ValueChanged<Department> onDelete;

  const _DepartmentsList({required this.departments, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final department = departments[index];
        final subtitleParts = [
          if (department.headOfDepartmentName != null) 'Head: ${department.headOfDepartmentName}',
          if (department.classes.isNotEmpty) 'Classes: ${department.classes.join(', ')}',
        ];
        return ListTile(
          title: Text(department.name),
          subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => onEdit(department),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => onDelete(department),
              ),
            ],
          ),
        );
      },
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

Future<void> _confirmDeleteDepartment(
  BuildContext context,
  DepartmentProvider provider,
  Department department,
) async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete department')),
    );
  }
}
