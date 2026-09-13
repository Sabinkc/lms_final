import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/academic_class.dart';
import '../providers/academic_structure_provider.dart';

/// docs/screens.md "Manage Classes / Sections / Subjects" — the Classes
/// half; tapping a class drills into [SectionsListScreen] for its Sections.
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
    Future.microtask(() => provider.loadClasses());
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicStructureProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClassFormDialog(context, provider),
        tooltip: 'Add Class',
        child: const Icon(Icons.add),
      ),
      body: switch (provider.classesStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading classes...'),
        LoadStatus.error => ErrorView(
            error: provider.classesError!,
            onRetry: () => provider.loadClasses(),
          ),
        LoadStatus.success => provider.classes.isEmpty
            ? EmptyStateView(
                message: 'No classes set up yet',
                icon: Icons.school_outlined,
                actionLabel: 'Add Class',
                onAction: () => _showClassFormDialog(context, provider),
              )
            : _ClassesList(
                searchController: _searchController,
                classes: provider.classes
                    .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query))
                    .toList(),
                onTap: (academicClass) => context.push(AppRoutes.adminClassSections(academicClass.id)),
                onEdit: (academicClass) => _showClassFormDialog(context, provider, existing: academicClass),
                onDelete: (academicClass) => _confirmDeleteClass(context, provider, academicClass),
              ),
      },
    );
  }
}

class _ClassesList extends StatelessWidget {
  final TextEditingController searchController;
  final List<AcademicClass> classes;
  final ValueChanged<AcademicClass> onTap;
  final ValueChanged<AcademicClass> onEdit;
  final ValueChanged<AcademicClass> onDelete;

  const _ClassesList({
    required this.searchController,
    required this.classes,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search classes',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: classes.isEmpty
              ? const EmptyStateView(message: 'No classes match your search')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: classes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final academicClass = classes[index];
                    final badgeColor = _badgeColors[index % _badgeColors.length];
                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            _classInitials(academicClass.name),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        title: Text(academicClass.name, style: Theme.of(context).textTheme.titleSmall),
                        subtitle: academicClass.description.isEmpty ? null : Text(academicClass.description),
                        onTap: () => onTap(academicClass),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              onPressed: () => onEdit(academicClass),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () => onDelete(academicClass),
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

/// Small fixed palette cycled by row index purely for visual variety — not
/// tied to any class data (`AcademicClass` has no color field).
const _badgeColors = [Color(0xFF4F46E5), Color(0xFFD97706), Color(0xFF059669), Color(0xFF9333EA)];

String _classInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return trimmed.length >= 2 ? trimmed.substring(0, 2).toUpperCase() : trimmed.toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

Future<void> _showClassFormDialog(
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

Future<void> _confirmDeleteClass(
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

  if (confirmed != true || !context.mounted) return;

  final succeeded = await provider.deleteClass(academicClass.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.classActionError?.message ?? 'Failed to delete class')),
    );
  }
}
