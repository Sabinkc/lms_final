import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_followup.dart';
import '../providers/student_followup_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

const _statusLabels = {null: 'All', 'pending': 'Pending', 'in-progress': 'In Progress', 'resolved': 'Resolved'};

/// Admin: Manage Student Follow-ups (`docs/production_roadmap.md` Phase L5,
/// `implementation_backlog.md` E18) — a CRM-style log of prospective/at-risk
/// student visits, same search+filter+export shell `AdminFeesScreen`/
/// `ClassesListScreen` already established.
class StudentFollowupsScreen extends StatefulWidget {
  const StudentFollowupsScreen({super.key});

  @override
  State<StudentFollowupsScreen> createState() => _StudentFollowupsScreenState();
}

class _StudentFollowupsScreenState extends State<StudentFollowupsScreen> {
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentFollowupProvider>();
    Future.microtask(() => provider.loadFollowups());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<StudentFollowupProvider>().loadFollowups(
          status: _statusFilter,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentFollowupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Follow-ups'),
        actions: [
          IconButton(
            icon: provider.isDownloading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Export follow-ups',
            onPressed: provider.isDownloading ? null : () => _downloadExport(context, provider, _statusFilter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFollowupFormDialog(context, provider),
        tooltip: 'Add Follow-up',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name, email, or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final entry in _statusLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _statusFilter == entry.key,
                    onSelected: (_) {
                      setState(() => _statusFilter = entry.key);
                      _reload();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (provider.status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading follow-ups...'),
              LoadStatus.error => ErrorView(error: provider.error!, onRetry: _reload),
              LoadStatus.success => provider.followups.isEmpty
                  ? EmptyStateView(
                      message: 'No follow-ups logged yet',
                      icon: Icons.support_agent_outlined,
                      actionLabel: 'Add Follow-up',
                      onAction: () => _showFollowupFormDialog(context, provider),
                    )
                  : ListView.builder(
                      itemCount: provider.followups.length,
                      itemBuilder: (context, index) => _FollowupTile(
                        followup: provider.followups[index],
                        onEdit: () => _showFollowupFormDialog(context, provider, existing: provider.followups[index]),
                        onDelete: () => _confirmDelete(context, provider, provider.followups[index]),
                      ),
                    ),
            },
          ),
        ],
      ),
    );
  }
}

class _FollowupTile extends StatelessWidget {
  final StudentFollowup followup;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FollowupTile({required this.followup, required this.onEdit, required this.onDelete});

  Color _statusColor(BuildContext context) => switch (followup.status) {
        'resolved' => Colors.green,
        'in-progress' => Colors.orange,
        _ => Theme.of(context).colorScheme.error,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(followup.studentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${followup.faculty} · ${followup.email}'),
            const SizedBox(height: 4),
            Text(followup.followUpNote, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: _statusColor(context).withValues(alpha: 0.15),
          child: Icon(Icons.person_outline, color: _statusColor(context)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

Future<void> _showFollowupFormDialog(
  BuildContext context,
  StudentFollowupProvider provider, {
  StudentFollowup? existing,
}) async {
  final nameController = TextEditingController(text: existing?.studentName);
  final facultyController = TextEditingController(text: existing?.faculty);
  final emailController = TextEditingController(text: existing?.email);
  final contactController = TextEditingController(text: existing?.contactNumber);
  final addressController = TextEditingController(text: existing?.address);
  final noteController = TextEditingController(text: existing?.followUpNote);
  final formKey = GlobalKey<FormState>();

  DateTime visitDate = existing?.visitDate != null ? DateTime.tryParse(existing!.visitDate!) ?? DateTime.now() : DateTime.now();
  String status = existing?.status ?? 'pending';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Follow-up' : 'Edit Follow-up'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Student Name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: facultyController,
                    decoration: const InputDecoration(labelText: 'Faculty'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Follow-up Needed'),
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Visit date: ${_formatDate(visitDate)}'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: visitDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => visitDate = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) => setDialogState(() => status = value ?? 'pending'),
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
                        ? await provider.createFollowup(
                            studentName: nameController.text.trim(),
                            faculty: facultyController.text.trim(),
                            email: emailController.text.trim(),
                            contactNumber: contactController.text.trim(),
                            address: addressController.text.trim(),
                            followUpNote: noteController.text.trim(),
                            visitDate: visitDate.toIso8601String(),
                            status: status,
                          )
                        : await provider.updateFollowup(
                            id: existing.id,
                            studentName: nameController.text.trim(),
                            faculty: facultyController.text.trim(),
                            email: emailController.text.trim(),
                            contactNumber: contactController.text.trim(),
                            address: addressController.text.trim(),
                            followUpNote: noteController.text.trim(),
                            visitDate: visitDate.toIso8601String(),
                            status: status,
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

Future<void> _confirmDelete(BuildContext context, StudentFollowupProvider provider, StudentFollowup followup) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete follow-up?'),
      content: Text('This will permanently delete the follow-up record for "${followup.studentName}". This cannot be undone.'),
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

  final succeeded = await provider.deleteFollowup(followup.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete follow-up')),
    );
  }
}

Future<void> _downloadExport(BuildContext context, StudentFollowupProvider provider, String? status) async {
  final bytes = await provider.exportFollowups(status: status);
  if (bytes != null) {
    if (context.mounted) await saveBytesOrNotify(context, bytes, 'student-followups.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export follow-ups')),
    );
  }
}
