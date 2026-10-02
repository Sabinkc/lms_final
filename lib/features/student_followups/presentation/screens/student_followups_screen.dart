import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_followup.dart';
import '../providers/student_followup_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

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

  Future<void> _refresh() async {
    final search = _searchController.text.trim();
    await context.read<StudentFollowupProvider>().loadFollowups(
      status: _statusFilter,
      search: search.isEmpty ? null : search,
      silent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentFollowupProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Student Follow-ups',
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
        body: PullToRefresh(
          onRefresh: _refresh,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _reload(),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppFilterChipBar<String?>(
                  options: _statusLabels.keys.toList(),
                  selected: _statusFilter,
                  labelBuilder: (key) => _statusLabels[key]!,
                  iconBuilder: (key) => key == null ? null : _statusStyle(key).icon,
                  onSelected: (key) {
                    setState(() => _statusFilter = key);
                    _reload();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: switch (provider.status) {
                  LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading follow-ups...'),
                  LoadStatus.error => ErrorView(error: provider.error!, onRetry: _reload),
                  LoadStatus.success =>
                    provider.followups.isEmpty
                        ? EmptyStateView(
                            message: 'No follow-ups logged yet',
                            icon: Icons.support_agent_outlined,
                            actionLabel: 'Add Follow-up',
                            onAction: () => _showFollowupFormDialog(context, provider),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            children: [
                              if (_statusFilter == null) ...[
                                _SummaryRow(followups: provider.followups),
                                const SizedBox(height: 12),
                              ],
                              for (final followup in provider.followups) ...[
                                _FollowupTile(
                                  followup: followup,
                                  onEdit: () => _showFollowupFormDialog(context, provider, existing: followup),
                                  onDelete: () => _confirmDelete(context, provider, followup),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({String label, IconData icon, Color color}) _statusStyle(String status) => switch (status) {
  'resolved' => (label: 'Resolved', icon: Icons.check_circle_outline, color: AppColors.success),
  'in-progress' => (label: 'In Progress', icon: Icons.timelapse, color: AppColors.info),
  _ => (label: 'Pending', icon: Icons.flag_outlined, color: AppColors.warning),
};

class _SummaryRow extends StatelessWidget {
  final List<StudentFollowup> followups;

  const _SummaryRow({required this.followups});

  @override
  Widget build(BuildContext context) {
    int count(String status) => followups.where((f) => f.status == status).length;
    return Row(
      children: [
        for (final (i, status) in const ['pending', 'in-progress', 'resolved'].indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: TintedStatTile(
              icon: _statusStyle(status).icon,
              label: _statusStyle(status).label,
              value: '${count(status)}',
              color: _statusStyle(status).color,
            ),
          ),
        ],
      ],
    );
  }
}

class _FollowupTile extends StatelessWidget {
  final StudentFollowup followup;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FollowupTile({required this.followup, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _statusStyle(followup.status);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final resolved = followup.status == 'resolved';

    return StaggeredEntrance(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: style.color.withValues(alpha: 0.12),
                    child: Text(
                      initialsFor(followup.studentName),
                      style: TextStyle(color: context.readable(style.color), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          followup.studentName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (followup.faculty.isNotEmpty)
                          AppStatusPill(label: followup.faculty, icon: Icons.school_outlined, color: AppColors.info),
                      ],
                    ),
                  ),
                  AppStatusPill(label: style.label, icon: style.icon, color: style.color),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      resolved ? Icons.check_circle_outline : Icons.format_quote_rounded,
                      size: 18,
                      color: context.readable(style.color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        followup.followUpNote,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  if (followup.contactNumber.isNotEmpty)
                    _Meta(icon: Icons.phone_outlined, text: followup.contactNumber, style: muted),
                  if (followup.email.isNotEmpty) _Meta(icon: Icons.mail_outline, text: followup.email, style: muted),
                  if (followup.visitDate != null)
                    _Meta(
                      icon: Icons.event_outlined,
                      text: 'Visit ${formatDisplayDate(followup.visitDate!)}',
                      style: muted,
                    ),
                  if (followup.createdByName != null)
                    _Meta(icon: Icons.person_outline, text: followup.createdByName!, style: muted),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;

  const _Meta({required this.icon, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: style?.color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
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

  DateTime visitDate = existing?.visitDate != null
      ? DateTime.tryParse(existing!.visitDate!) ?? DateTime.now()
      : DateTime.now();
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
                          if (picked != null) {
                            setDialogState(() => visitDate = picked);
                          }
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
                    if (succeeded && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
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
      content: Text(
        'This will permanently delete the follow-up record for "${followup.studentName}". This cannot be undone.',
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

  final succeeded = await runWithProgress(context, () => provider.deleteFollowup(followup.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete follow-up')));
  }
}

Future<void> _downloadExport(BuildContext context, StudentFollowupProvider provider, String? status) async {
  final bytes = await provider.exportFollowups(status: status);
  if (bytes != null) {
    if (context.mounted) {
      await saveBytesOrNotify(context, bytes, 'student-followups.xlsx');
    }
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export follow-ups')));
  }
}
