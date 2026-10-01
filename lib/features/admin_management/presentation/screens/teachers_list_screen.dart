import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/teacher.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/teacher_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// docs/screens.md "Manage Teachers — List / Add-Edit / Detail". No separate
/// detail screen — same P0-only scope decision as Classes/Sections; the P1
/// detail view (`implementation_backlog.md` E2-F2-T3) is parked, the edit
/// dialog already surfaces every field a detail view would.
class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // See ClassesListScreen.initState's comment: deferred to a microtask so
    // loadTeachers()'s synchronous-before-first-`await` notifyListeners()
    // doesn't fire mid-build.
    final provider = context.read<TeacherProvider>();
    Future.microtask(() => provider.loadTeachers());
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Teachers'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showTeacherFormDialog(context, provider),
          tooltip: 'Add Teacher',
          child: const Icon(Icons.add),
        ),
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading teachers...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadTeachers()),
          LoadStatus.success =>
            provider.teachers.isEmpty
                ? EmptyStateView(
                    message: 'No teachers added yet',
                    icon: Icons.person_outline,
                    actionLabel: 'Add Teacher',
                    onAction: () => _showTeacherFormDialog(context, provider),
                  )
                : _TeachersList(
                    searchController: _searchController,
                    teachers: provider.teachers
                        .where(
                          (t) =>
                              _query.isEmpty ||
                              t.fullName.toLowerCase().contains(_query) ||
                              t.department.toLowerCase().contains(_query),
                        )
                        .toList(),
                    onEdit: (teacher) => _showTeacherFormDialog(context, provider, existing: teacher),
                    onDelete: (teacher) => _confirmDeleteTeacher(context, provider, teacher),
                  ),
        },
      ),
    );
  }
}

class _TeachersList extends StatelessWidget {
  final TextEditingController searchController;
  final List<Teacher> teachers;
  final ValueChanged<Teacher> onEdit;
  final ValueChanged<Teacher> onDelete;

  const _TeachersList({
    required this.searchController,
    required this.teachers,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search teachers by name or department',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: teachers.isEmpty
              ? const EmptyStateView(message: 'No teachers match your search')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: teachers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    final accent = scheme.primary;
                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.14),
                          child: Text(
                            teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(teacher.fullName, style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: scheme.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${teacher.department} · ${teacher.employeeId} · ${teacher.email}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              onPressed: () => onEdit(teacher),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () => onDelete(teacher),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<void> _showTeacherFormDialog(BuildContext context, TeacherProvider provider, {Teacher? existing}) async {
  final fullNameController = TextEditingController(text: existing?.fullName);
  final emailController = TextEditingController(text: existing?.email);
  final employeeIdController = TextEditingController(text: existing?.employeeId);
  final departmentController = TextEditingController(text: existing?.department);
  final qualificationController = TextEditingController(text: existing?.qualification);
  final phoneController = TextEditingController(text: existing?.phone);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Teacher' : 'Edit Teacher'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  enabled: existing == null,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Full name is required' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: existing == null,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: employeeIdController,
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Employee ID is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Department is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qualificationController,
                  decoration: const InputDecoration(labelText: 'Qualification (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
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
                        ? await provider.createTeacher(
                            fullName: fullNameController.text.trim(),
                            email: emailController.text.trim(),
                            employeeId: employeeIdController.text.trim(),
                            department: departmentController.text.trim(),
                            qualification: qualificationController.text.trim(),
                            phone: phoneController.text.trim(),
                          )
                        : await provider.updateTeacher(
                            id: existing.id,
                            employeeId: employeeIdController.text.trim(),
                            department: departmentController.text.trim(),
                            qualification: qualificationController.text.trim(),
                            phone: phoneController.text.trim(),
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

Future<void> _confirmDeleteTeacher(BuildContext context, TeacherProvider provider, Teacher teacher) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete teacher?'),
      content: Text(
        'This will permanently delete "${teacher.fullName}" and their login account. This cannot be undone.',
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

  final succeeded = await provider.deleteTeacher(teacher.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete teacher')));
  }
}
