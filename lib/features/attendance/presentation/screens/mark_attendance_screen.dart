import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_status.dart';
import '../providers/attendance_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// docs/screens.md "Mark Attendance" (Teacher). Locks immediately on submit
/// — confirmed no Teacher-facing edit path exists afterward
/// (`implementation_backlog.md` E3-F1-T4) — so a successful submit disables
/// further edits on this screen rather than leaving it re-submittable.
class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _subjectController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    Future.microtask(() => provider.loadMySections());
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: switch (provider.sectionsStatus) {
                        LoadStatus.initial || LoadStatus.loading =>
                          const LinearProgressIndicator(),
                        LoadStatus.error => Text(
                            provider.sectionsError!.message,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        LoadStatus.success => DropdownButtonFormField<String>(
                            initialValue: _selectedSectionId,
                            decoration: const InputDecoration(labelText: 'Section'),
                            items: [
                              for (final s in provider.sections)
                                DropdownMenuItem(value: s.id, child: Text('${s.className} — ${s.name}')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSectionId = value);
                              if (value != null) provider.loadRoster(value);
                            },
                          ),
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(_date)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject (optional, defaults to "General")'),
                ),
              ],
            ),
          ),
          Expanded(child: _RosterBody(sectionId: _selectedSectionId)),
        ],
      ),
      bottomNavigationBar: _selectedSectionId == null || provider.rosterStatus != LoadStatus.success
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SubmitBar(sectionId: _selectedSectionId!, date: _date, subjectController: _subjectController),
              ),
            ),
    );
  }
}

class _RosterBody extends StatelessWidget {
  final String? sectionId;

  const _RosterBody({required this.sectionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (sectionId == null) {
      return const EmptyStateView(message: 'Pick a section to load its roster', icon: Icons.groups_outlined);
    }

    return switch (provider.rosterStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading roster...'),
      LoadStatus.error => ErrorView(error: provider.rosterError!, onRetry: () => provider.loadRoster(sectionId!)),
      LoadStatus.success => provider.roster.isEmpty
          ? const EmptyStateView(message: 'No students in this section')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.roster.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final student = provider.roster[index];
                final locked = provider.lastSubmitResult != null;
                final current = provider.statusFor(student.id);
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.fullName, style: Theme.of(context).textTheme.titleSmall),
                        Text(student.admissionNumber, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final status in AttendanceStatus.values)
                              ChoiceChip(
                                label: Text(status.label),
                                selected: current == status,
                                showCheckmark: false,
                                onSelected: locked ? null : (_) => provider.setStatus(student.id, status),
                              ),
                          ],
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

class _SubmitBar extends StatelessWidget {
  final String sectionId;
  final DateTime date;
  final TextEditingController subjectController;

  const _SubmitBar({required this.sectionId, required this.date, required this.subjectController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (provider.lastSubmitResult case final result?) {
      return Text(
        'Attendance submitted and locked: ${result.savedCount} recorded'
        '${result.failed.isEmpty ? '' : ', ${result.failed.length} failed'}.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.submitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              provider.submitError!.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: provider.isSubmitting
              ? null
              : () => provider.submit(
                    sectionId: sectionId,
                    date: _formatDate(date),
                    subject: subjectController.text.trim(),
                  ),
          child: provider.isSubmitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit attendance'),
        ),
      ],
    );
  }
}
