import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/subject_icon.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/assignment.dart';
import '../../data/models/assignment_submission.dart';
import '../../data/repositories/assignment_repository.dart' show SubmissionFile;
import '../providers/assignment_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

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

  Future<void> _refresh() async {
    final provider = context.read<AssignmentProvider>();
    final role = context.read<AuthProvider>().role;
    await Future.wait([
      provider.loadAssignmentDetail(widget.assignmentId, silent: true),
      if (role == AppRole.teacher)
        provider.loadSubmissionsForAssignment(widget.assignmentId, silent: true)
      else if (role == AppRole.student)
        provider.loadMySubmissions(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final role = context.watch<AuthProvider>().role;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Assignment'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.detailStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading assignment...'),
            LoadStatus.error => ErrorView(
              error: provider.detailError!,
              onRetry: () => provider.loadAssignmentDetail(widget.assignmentId),
            ),
            LoadStatus.success => _DetailBody(assignment: provider.currentAssignment!, role: role),
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Assignment assignment;
  final AppRole? role;

  const _DetailBody({required this.assignment, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = assignment.status == 'closed';
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(subjectIcon(assignment.subject), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (closed) const AppStatusPill(label: 'Closed', icon: Icons.lock_outline, color: Colors.white),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(icon: Icons.menu_book_outlined, label: assignment.subject),
                  _MetaPill(icon: Icons.class_outlined, label: '${assignment.className} ${assignment.section}'),
                  _MetaPill(icon: Icons.event_outlined, label: 'Due ${formatDisplayDate(assignment.dueDate)}'),
                ],
              ),
            ],
          ),
        ),
        if (assignment.description.isNotEmpty || assignment.attachment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            icon: Icons.description_outlined,
            title: 'Task Specification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (assignment.description.isNotEmpty)
                  Text(assignment.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                if (assignment.attachment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const InfoStrip(icon: Icons.attach_file_rounded, text: 'Attached resource', trailing: 'Teacher file'),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        switch (role) {
          AppRole.teacher => _TeacherSubmissions(assignment: assignment),
          AppRole.student => _StudentSubmission(assignment: assignment),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
      LoadStatus.initial || LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => Text(
        provider.submissionsError!.message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      LoadStatus.success => () {
        final submissions = provider.submissions;
        final graded = submissions.where((s) => s.graded).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Submissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                AppStatusPill(label: '${submissions.length}', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            if (submissions.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [Icon(Icons.inbox_outlined, size: 36), SizedBox(height: 8), Text('No submissions yet')],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TintedStatTile(
                      icon: Icons.task_alt_rounded,
                      label: 'Graded',
                      value: '$graded',
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TintedStatTile(
                      icon: Icons.pending_actions_rounded,
                      label: 'To grade',
                      value: '${submissions.length - graded}',
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final submission in submissions) ...[
                _SubmissionCard(submission: submission),
                const SizedBox(height: 10),
              ],
            ],
          ],
        );
      }(),
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
    final name = submission.studentName ?? submission.studentAdmissionNumber ?? 'Unknown student';
    final theme = Theme.of(context);
    final files = submission.attachments.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initialsFor(name),
                    style: TextStyle(color: context.readable(AppColors.primary), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      if (submission.submittedAt.isNotEmpty)
                        Text(
                          'Submitted ${formatDisplayDate(submission.submittedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (submission.graded)
                  const AppStatusPill(label: 'Graded', icon: Icons.check_circle_outline, color: Color(0xFF16A34A))
                else
                  const AppStatusPill(label: 'Pending', icon: Icons.schedule, color: Color(0xFFEA580C)),
              ],
            ),
            if (submission.submissionText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text('“${submission.submissionText}”', style: theme.textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 8),
            InfoStrip(
              icon: Icons.attach_file_rounded,
              text: files == 0 ? 'No files attached' : '$files file${files == 1 ? '' : 's'} attached',
              color: AppColors.info,
            ),
            const SizedBox(height: 10),
            if (submission.graded)
              InfoStrip(
                icon: Icons.grade_outlined,
                text: 'Marks: ${submission.marks}${submission.remarks.isNotEmpty ? ' — ${submission.remarks}' : ''}',
                color: const Color(0xFF16A34A),
              )
            else
              FilledButton.icon(
                onPressed: grading ? null : () => _showGradeDialog(context, provider, submission),
                icon: grading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Grade'),
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
              validator: (value) => (num.tryParse(value ?? '') == null) ? 'Enter a valid number' : null,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Remarks (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
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
          Text(provider.submissionsError!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => provider.loadMySubmissions(), child: const Text('Retry')),
        ],
      );
    }

    if (provider.submissionsStatus != LoadStatus.success) {
      return const Center(child: CircularProgressIndicator());
    }

    final existing = provider.submissions.where((s) => s.assignmentId == widget.assignment.id);
    final mySubmission = existing.isEmpty ? null : existing.first;

    if (mySubmission != null && mySubmission.graded) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your submission has been graded',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Marks: ${mySubmission.marks}',
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
            ),
            if (mySubmission.remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  '“${mySubmission.remarks}”',
                  style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  'Submission locked after grading',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.upload_file_rounded,
      title: mySubmission == null ? 'Submit your work' : 'Resubmit your work',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mySubmission != null) ...[
            InfoStrip(
              icon: Icons.check_circle_outline,
              text: mySubmission.submittedAt.isNotEmpty
                  ? 'Submitted ${formatDisplayDate(mySubmission.submittedAt)} · you can resubmit until graded'
                  : 'Submitted · you can resubmit until graded',
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Submission text (optional)',
              alignLabelWithHint: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () async {
              final files = await FilePicker.pickFiles();
              if (files.isEmpty) return;
              final withBytes = <SubmissionFile>[];
              for (final f in files.take(5)) {
                withBytes.add(SubmissionFile(bytes: await f.readAsBytes(), filename: f.name));
              }
              setState(() {
                _pickedFiles
                  ..clear()
                  ..addAll(withBytes);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: context.readable(AppColors.info), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    _pickedFiles.isEmpty ? 'Attach files (up to 5)' : '${_pickedFiles.length} file(s) selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.readable(AppColors.info),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_pickedFiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(
                        _pickedFiles.map((f) => f.filename).join(', '),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (provider.submitError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(provider.submitError!.message, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
            icon: provider.isSubmitting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(mySubmission == null ? 'Submit' : 'Resubmit'),
          ),
        ],
      ),
    );
  }
}
