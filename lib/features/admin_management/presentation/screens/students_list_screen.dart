import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/file_download.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/student.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/student_provider.dart';

/// docs/screens.md "Manage Students — List / Add-Edit / Detail". No separate
/// detail screen, same P0-only scope decision as Classes/Sections/Teachers.
/// Parent linking (`parentId`) is deferred to Phase B4 — there's no Parent
/// list yet to pick from, so the create/edit form doesn't expose that field.
class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentProvider>();
    Future.microtask(() {
      provider.loadStudents();
      provider.loadClassOptions();
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
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Bulk import',
            onPressed: () => _showBulkImportDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export students',
            onPressed: () => _downloadExport(context, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentFormDialog(context, provider),
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _ClassFilterBar(
            classOptions: provider.classOptions,
            selected: provider.classFilter,
            onChanged: (className) => provider.loadStudents(className: className),
          ),
          Expanded(
            child: switch (provider.status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading students...'),
              LoadStatus.error => ErrorView(
                  error: provider.error!,
                  onRetry: () => provider.loadStudents(className: provider.classFilter),
                ),
              LoadStatus.success => provider.students.isEmpty
                  ? EmptyStateView(
                      message: 'No students added yet',
                      icon: Icons.school_outlined,
                      actionLabel: 'Add Student',
                      onAction: () => _showStudentFormDialog(context, provider),
                    )
                  : _StudentsList(
                      searchController: _searchController,
                      students: provider.students
                          .where((s) =>
                              _query.isEmpty ||
                              s.fullName.toLowerCase().contains(_query) ||
                              s.admissionNumber.toLowerCase().contains(_query))
                          .toList(),
                      onEdit: (student) => _showStudentFormDialog(context, provider, existing: student),
                      onDelete: (student) => _confirmDeleteStudent(context, provider, student),
                    ),
            },
          ),
        ],
      ),
    );
  }
}

class _ClassFilterBar extends StatelessWidget {
  final List<AcademicClass> classOptions;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _ClassFilterBar({required this.classOptions, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (classOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: const Text('All'), selected: selected == null, onSelected: (_) => onChanged(null)),
            ),
            for (final c in classOptions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: selected == c.name,
                  onSelected: (_) => onChanged(c.name),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentsList extends StatelessWidget {
  final TextEditingController searchController;
  final List<Student> students;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student> onDelete;

  const _StudentsList({
    required this.searchController,
    required this.students,
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
              labelText: 'Search students by name or admission number',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const EmptyStateView(message: 'No students match your search')
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text(student.fullName),
                      subtitle: Text(
                        '${student.className} · ${student.section}'
                        '${student.admissionNumber.isEmpty ? '' : ' · ${student.admissionNumber}'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => onEdit(student),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => onDelete(student),
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

Future<void> _showStudentFormDialog(
  BuildContext context,
  StudentProvider provider, {
  Student? existing,
}) async {
  final fullNameController = TextEditingController(text: existing?.fullName);
  final emailController = TextEditingController(text: existing?.email);
  final admissionController = TextEditingController(text: existing?.admissionNumber);
  final rollController = TextEditingController(text: existing?.rollNumber);
  final phoneController = TextEditingController(text: existing?.phone);
  final formKey = GlobalKey<FormState>();

  String? selectedClass = existing?.className;
  String? selectedSection = existing?.section;
  if (selectedClass != null) {
    final matching = provider.classOptions.where((c) => c.name == selectedClass);
    if (matching.isNotEmpty) await provider.loadSectionOptions(matching.first.id);
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student'),
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
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    for (final c in provider.classOptions) DropdownMenuItem(value: c.name, child: Text(c.name)),
                  ],
                  validator: (value) => value == null ? 'Class is required' : null,
                  onChanged: (value) async {
                    selectedClass = value;
                    selectedSection = null;
                    final matching = provider.classOptions.where((c) => c.name == value);
                    if (matching.isNotEmpty) await provider.loadSectionOptions(matching.first.id);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSection,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: [
                    for (final s in provider.sectionOptions) DropdownMenuItem(value: s.name, child: Text(s.name)),
                  ],
                  validator: (value) => value == null ? 'Section is required' : null,
                  onChanged: (value) {
                    selectedSection = value;
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: admissionController,
                  decoration: const InputDecoration(labelText: 'Admission number (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rollController,
                  decoration: const InputDecoration(labelText: 'Roll number (optional)'),
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
                        ? await provider.createStudent(
                            className: selectedClass!,
                            section: selectedSection!,
                            fullName: fullNameController.text.trim(),
                            email: emailController.text.trim(),
                            admissionNumber: admissionController.text.trim(),
                            rollNumber: rollController.text.trim(),
                            phone: phoneController.text.trim(),
                          )
                        : await provider.updateStudent(
                            id: existing.id,
                            className: selectedClass,
                            section: selectedSection,
                            admissionNumber: admissionController.text.trim(),
                            rollNumber: rollController.text.trim(),
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

Future<void> _confirmDeleteStudent(
  BuildContext context,
  StudentProvider provider,
  Student student,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete student?'),
      content: Text(
        'This will permanently delete "${student.fullName}" and their login account. This cannot be undone.',
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

  final succeeded = await provider.deleteStudent(student.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete student')),
    );
  }
}

Future<void> _showBulkImportDialog(BuildContext context, StudentProvider provider) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Bulk import students'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload an Excel (.xlsx/.xls) or CSV file with Full Name, Email, Class, Section columns.'),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Download template'),
                onPressed: () async {
                  final bytes = await provider.downloadImportTemplate();
                  if (bytes != null) saveBytesAsFile(bytes, 'student_import_template.xlsx');
                },
              ),
              const SizedBox(height: 12),
              if (provider.isImporting) const Center(child: CircularProgressIndicator()),
              if (provider.importError != null)
                Text(
                  provider.importError!.message,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              if (provider.lastImportResult case final result?) ...[
                Text('${result.createdCount} of ${result.totalRows} rows imported.'),
                for (final f in result.failed) Text('Row ${f.row}: ${f.reason}', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Choose file'),
            onPressed: provider.isImporting
                ? null
                : () async {
                    final file = await FilePicker.pickFile(
                      type: FileType.custom,
                      allowedExtensions: ['xlsx', 'xls', 'csv'],
                    );
                    if (file == null) return;
                    await provider.bulkImport(await file.readAsBytes(), file.name);
                    setDialogState(() {});
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _downloadExport(BuildContext context, StudentProvider provider) async {
  final bytes = await provider.exportStudents();
  if (bytes != null) {
    saveBytesAsFile(bytes, 'student_roster.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export students')),
    );
  }
}
