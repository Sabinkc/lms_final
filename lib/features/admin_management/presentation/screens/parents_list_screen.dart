import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/parent.dart';
import '../../data/models/student.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/parent_provider.dart';

/// docs/screens.md "Manage Parents — List / Add-Edit". No separate detail
/// screen — same P0-only scope decision as the rest of Phase B. Linkage is
/// many-to-many (`Parent.students`) so the add/edit form's child picker is a
/// multi-select checklist, not a single dropdown.
class ParentsListScreen extends StatefulWidget {
  const ParentsListScreen({super.key});

  @override
  State<ParentsListScreen> createState() => _ParentsListScreenState();
}

class _ParentsListScreenState extends State<ParentsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<ParentProvider>();
    Future.microtask(() {
      provider.loadParents();
      provider.loadStudentOptions();
    });
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Parents')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showParentFormDialog(context, provider),
        tooltip: 'Add Parent',
        child: const Icon(Icons.add),
      ),
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading parents...'),
        LoadStatus.error => ErrorView(
            error: provider.error!,
            onRetry: () => provider.loadParents(),
          ),
        LoadStatus.success => provider.parents.isEmpty
            ? EmptyStateView(
                message: 'No parents added yet',
                icon: Icons.family_restroom_outlined,
                actionLabel: 'Add Parent',
                onAction: () => _showParentFormDialog(context, provider),
              )
            : _ParentsList(
                searchController: _searchController,
                parents:
                    provider.parents.where((p) => _query.isEmpty || p.fullName.toLowerCase().contains(_query)).toList(),
                onEdit: (parent) => _showParentFormDialog(context, provider, existing: parent),
                onDelete: (parent) => _confirmDeleteParent(context, provider, parent),
              ),
      },
    );
  }
}

class _ParentsList extends StatelessWidget {
  final TextEditingController searchController;
  final List<Parent> parents;
  final ValueChanged<Parent> onEdit;
  final ValueChanged<Parent> onDelete;

  const _ParentsList({
    required this.searchController,
    required this.parents,
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
              labelText: 'Search parents by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: parents.isEmpty
              ? const EmptyStateView(message: 'No parents match your search')
              : ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];
                    final childNames = parent.children.map((c) => c.fullName).join(', ');
                    return ListTile(
                      title: Text(parent.fullName),
                      subtitle: Text(childNames.isEmpty ? 'No children linked' : 'Children: $childNames'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => onEdit(parent),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => onDelete(parent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<void> _showParentFormDialog(
  BuildContext context,
  ParentProvider provider, {
  Parent? existing,
}) async {
  final fullNameController = TextEditingController(text: existing?.fullName);
  final emailController = TextEditingController(text: existing?.email);
  final occupationController = TextEditingController(text: existing?.occupation);
  final phoneController = TextEditingController(text: existing?.phone);
  final formKey = GlobalKey<FormState>();

  final selectedStudentIds = <String>{for (final c in existing?.children ?? const <Student>[]) c.id};

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Parent' : 'Edit Parent'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
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
                    controller: occupationController,
                    decoration: const InputDecoration(labelText: 'Occupation (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: Text('Linked children', style: Theme.of(dialogContext).textTheme.labelLarge)),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: provider.studentOptions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No students available yet'),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final student in provider.studentOptions)
                                CheckboxListTile(
                                  dense: true,
                                  title: Text(student.fullName),
                                  subtitle: Text('${student.className} · ${student.section}'),
                                  value: selectedStudentIds.contains(student.id),
                                  onChanged: (checked) {
                                    if (checked == true) {
                                      selectedStudentIds.add(student.id);
                                    } else {
                                      selectedStudentIds.remove(student.id);
                                    }
                                    setDialogState(() {});
                                  },
                                ),
                            ],
                          ),
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
                        ? await provider.createParent(
                            fullName: fullNameController.text.trim(),
                            email: emailController.text.trim(),
                            occupation: occupationController.text.trim(),
                            phone: phoneController.text.trim(),
                            studentIds: selectedStudentIds.toList(),
                          )
                        : await provider.updateParent(
                            id: existing.id,
                            occupation: occupationController.text.trim(),
                            phone: phoneController.text.trim(),
                            studentIds: selectedStudentIds.toList(),
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

Future<void> _confirmDeleteParent(
  BuildContext context,
  ParentProvider provider,
  Parent parent,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete parent?'),
      content: Text(
        'This will permanently delete "${parent.fullName}" and their login account, and unlink any children. '
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

  final succeeded = await provider.deleteParent(parent.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete parent')),
    );
  }
}
