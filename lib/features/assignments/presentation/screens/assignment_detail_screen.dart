import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/assignment.dart';
import '../../data/models/assignment_submission.dart';
import '../../data/repositories/assignment_repository.dart' show SubmissionFile;
import '../providers/assignment_provider.dart';

/// docs/screens.md's Assignment Detail — one screen, body adapts by role:
/// Teacher sees the submissions list with a grade action, Student sees
/// their own submission status and a submit/resubmit form, Parent/Admin
/// get the read-only assignment info only (`getAssignmentSubmissions` is
/// Teacher-only server-side — nothing to call for the other two roles).
class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // `role` is read inside the microtask, not captured here synchronously —
    // `AuthProvider`'s own restore-session call is also async, and reading
    // `.role` too early (before that settles) would silently skip both
    // branches below. The router already guarantees a resolved role by the
    // time any authenticated route builds in the real app, but this screen
    // shouldn't rely on that ordering to be correct.
    final provider = context.read<AssignmentProvider>();
    final authProvider = context.read<AuthProvider>();
    Future.microtask(() {
      provider.loadAssignmentDetail(widget.assignmentId);
      final role = authProvider.role;
      if (role == AppRole.teacher) {
        provider.loadSubmissionsForAssignment(widget.assignmentId);
      } else if (role == AppRole.student) {
        provider.loadMySubmissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final role = context.watch<AuthProvider>().role;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: switch (provider.detailStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(
          message: 'Loading assignment...',
        ),
        LoadStatus.error => ErrorView(
          error: provider.detailError!,
          onRetry: () => provider.loadAssignmentDetail(widget.assignmentId),
        ),
        LoadStatus.success => _DetailBody(
          assignment: provider.currentAssignment!,
          role: role,
        ),
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Assignment assignment;
  final AppRole? role;

  const _DetailBody({required this.assignment, required this.role});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (assignment.status == 'closed')
                      const AppStatusChip(label: 'Closed', color: Colors.grey),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${assignment.subject} · ${assignment.className} ${assignment.section}',
                ),
                Text('Due: ${formatDisplayDate(assignment.dueDate)}'),
                if (assignment.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(assignment.description),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        switch (role) {
          AppRole.teacher => _TeacherSubmissions(assignment: assignment),
          AppRole.student => _StudentSubmission(assignment: assignment),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _TeacherSubmissions extends StatelessWidget {
  final Assignment assignment;

  const _TeacherSubmissions({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();

    return switch (provider.submissionsStatus) {
      LoadStatus.initial ||
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => Text(
        provider.submissionsError!.message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      LoadStatus.success =>
        provider.submissions.isEmpty
            ? const Text('No submissions yet')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submissions (${provider.submissions.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final submission in provider.submissions)
                    _SubmissionCard(submission: submission),
                ],
              ),
    };
  }
}

class _SubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;

  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final grading = provider.isGrading(submission.id);
    final name =
        submission.studentName ??
        submission.studentAdmissionNumber ??
        'Unknown student';
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (submission.graded)
                  const AppStatusChip(label: 'Graded', color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            if (submission.submissionText.isNotEmpty)
              Text(submission.submissionText),
            Text('${submission.attachments.length} file(s) attached'),
            const SizedBox(height: 8),
            if (submission.graded)
              Text('Marks: ${submission.marks} — ${submission.remarks}')
            else
              FilledButton(
                onPressed: grading
                    ? null
                    : () => _showGradeDialog(context, provider, submission),
                child: grading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Grade'),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showGradeDialog(
  BuildContext context,
  AssignmentProvider provider,
  AssignmentSubmission submission,
) async {
  final marksController = TextEditingController();
  final remarksController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Grade submission'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: marksController,
              decoration: const InputDecoration(labelText: 'Marks'),
              keyboardType: TextInputType.number,
              validator: (value) => (num.tryParse(value ?? '') == null)
                  ? 'Enter a valid number'
                  : null,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final succeeded = await provider.gradeSubmission(
              submissionId: submission.id,
              marks: num.parse(marksController.text),
              remarks: remarksController.text.trim(),
            );
            if (succeeded && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _StudentSubmission extends StatefulWidget {
  final Assignment assignment;

  const _StudentSubmission({required this.assignment});

  @override
  State<_StudentSubmission> createState() => _StudentSubmissionState();
}

class _StudentSubmissionState extends State<_StudentSubmission> {
  final _textController = TextEditingController();
  final List<SubmissionFile> _pickedFiles = [];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();

    if (provider.submissionsStatus == LoadStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.submissionsError!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => provider.loadMySubmissions(),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (provider.submissionsStatus != LoadStatus.success) {
      return const Center(child: CircularProgressIndicator());
    }

    final existing = provider.submissions.where(
      (s) => s.assignmentId == widget.assignment.id,
    );
    final mySubmission = existing.isEmpty ? null : existing.first;

    if (mySubmission != null && mySubmission.graded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(child: Text('Your submission has been graded')),
                  AppStatusChip(label: 'Graded', color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text('Marks: ${mySubmission.marks}'),
              if (mySubmission.remarks.isNotEmpty)
                Text('Remarks: ${mySubmission.remarks}'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mySubmission == null ? 'Submit your work' : 'Resubmit your work',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Submission text (optional)',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.attach_file),
          label: Text(
            _pickedFiles.isEmpty
                ? 'Attach files (up to 5)'
                : '${_pickedFiles.length} file(s) selected',
          ),
          onPressed: () async {
            final files = await FilePicker.pickFiles();
            if (files.isEmpty) return;
            final withBytes = <SubmissionFile>[];
            for (final f in files.take(5)) {
              withBytes.add(
                SubmissionFile(bytes: await f.readAsBytes(), filename: f.name),
              );
            }
            setState(() {
              _pickedFiles
                ..clear()
                ..addAll(withBytes);
            });
          },
        ),
        if (provider.submitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              provider.submitError!.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: provider.isSubmitting
              ? null
              : () async {
                  final succeeded = await provider.submitAssignment(
                    assignmentId: widget.assignment.id,
                    submissionText: _textController.text.trim(),
                    files: _pickedFiles,
                  );
                  if (succeeded) provider.loadMySubmissions();
                },
          child: provider.isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(mySubmission == null ? 'Submit' : 'Resubmit'),
        ),
      ],
    );
  }
}
