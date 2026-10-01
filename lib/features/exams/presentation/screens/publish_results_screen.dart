import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/exam.dart';
import '../providers/exam_result_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

/// Admin: enter every student's marks per subject for one exam, then
/// publish in one call (`docs/production_roadmap.md` Phase F — System B,
/// the user's confirmed choice). Roster sourced the same way Attendance's
/// Mark Attendance screen sources its roster: fetch once, hold local edits,
/// submit as one array.
class PublishResultsScreen extends StatefulWidget {
  final Exam exam;

  const PublishResultsScreen({super.key, required this.exam});

  @override
  State<PublishResultsScreen> createState() => _PublishResultsScreenState();
}

class _PublishResultsScreenState extends State<PublishResultsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ExamResultProvider>();
    Future.microtask(() => provider.loadRosterForExam(widget.exam));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();
    final exam = widget.exam;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Publish Results'),
        body: switch (provider.rosterStatus) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading roster...'),
          LoadStatus.error => ErrorView(error: provider.rosterError!, onRetry: () => provider.loadRosterForExam(exam)),
          LoadStatus.success =>
            provider.published
                ? _PublishedView(exam: exam)
                : provider.roster.isEmpty
                ? const EmptyStateView(message: 'No students found in this class', icon: Icons.groups_outlined)
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          children: [
                            _ExamHeader(provider: provider, exam: exam),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Text(
                                  'Student Roster',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                AppStatusPill(label: '${provider.roster.length}', color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final student in provider.roster) ...[
                              _StudentMarksCard(provider: provider, student: student, subjects: exam.subjects),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      _PublishBar(provider: provider, exam: exam),
                    ],
                  ),
        },
      ),
    );
  }
}

String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

/// Counts (filled, total) mark cells across the whole roster.
(int, int) _entryProgress(ExamResultProvider provider, List<ExamSubject> subjects) {
  var filled = 0;
  for (final student in provider.roster) {
    for (final subject in subjects) {
      if (provider.markFor(student.id, subject.name) != null) filled++;
    }
  }
  return (filled, provider.roster.length * subjects.length);
}

class _ExamHeader extends StatelessWidget {
  final ExamResultProvider provider;
  final Exam exam;

  const _ExamHeader({required this.provider, required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (filled, total) = _entryProgress(provider, exam.subjects);
    final progress = total == 0 ? 0.0 : filled / total;
    final ready = total > 0 && filled == total;
    final readyColor = ready ? const Color(0xFF16A34A) : const Color(0xFFEA580C);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(Icons.fact_check_outlined, color: context.readable(AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${exam.className}${exam.section != null ? ' · Section ${exam.section}' : ''} · '
                        '${_plural(provider.roster.length, 'student')} · ${_plural(exam.subjects.length, 'subject')}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppStatusPill(
                  label: ready ? 'Ready' : 'In progress',
                  icon: ready ? Icons.check_circle_outline : Icons.edit_note_rounded,
                  color: readyColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Marks Entered', style: theme.textTheme.labelMedium)),
                      Text(
                        '$filled/$total',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: readyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      color: readyColor,
                      backgroundColor: readyColor.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Once published, results become visible to students and parents in their apps.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentMarksCard extends StatelessWidget {
  final ExamResultProvider provider;
  final Student student;
  final List<ExamSubject> subjects;

  const _StudentMarksCard({required this.provider, required this.student, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marks = [for (final s in subjects) provider.markFor(student.id, s.name)];
    final complete = marks.isNotEmpty && marks.every((m) => m != null);
    final obtained = marks.fold<int>(0, (sum, m) => sum + (m ?? 0));
    final full = subjects.fold<int>(0, (sum, s) => sum + s.fullMarks);

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
                    initialsFor(student.fullName),
                    style: TextStyle(color: context.readable(AppColors.primary), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.fullName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (complete)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppStatusPill(
                        label: full == 0 ? '—' : '${(obtained * 100 / full).toStringAsFixed(1)}%',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 2),
                      Text('$obtained / $full', style: theme.textTheme.bodySmall),
                    ],
                  )
                else
                  Text(
                    '${marks.where((m) => m != null).length}/${subjects.length} entered',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final perRow = constraints.maxWidth > 420 ? 4 : 3;
                final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: 10,
                  children: [
                    for (final subject in subjects)
                      SizedBox(
                        width: width,
                        child: _MarkField(provider: provider, student: student, subject: subject),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkField extends StatelessWidget {
  final ExamResultProvider provider;
  final Student student;
  final ExamSubject subject;

  const _MarkField({required this.provider, required this.student, required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = provider.markFor(student.id, subject.name);
    final failing = mark != null && mark < subject.passMarks;
    final invalid = mark != null && mark > subject.fullMarks;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject.name,
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '/${subject.fullMarks}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey('${student.id}-${subject.name}'),
          initialValue: mark?.toString(),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: invalid || failing ? AppColors.danger : null,
          ),
          decoration: InputDecoration(
            hintText: '–',
            isDense: true,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            fillColor: (invalid || failing ? AppColors.danger : AppColors.info).withValues(alpha: 0.07),
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          onChanged: (value) => provider.setMark(student.id, subject.name, int.tryParse(value)),
        ),
      ],
    );
  }
}

class _PublishBar extends StatelessWidget {
  final ExamResultProvider provider;
  final Exam exam;

  const _PublishBar({required this.provider, required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (filled, total) = _entryProgress(provider, exam.subjects);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.publishError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(provider.publishError!.message, style: TextStyle(color: theme.colorScheme.error)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$filled of $total marks entered',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              FilledButton.icon(
                onPressed: provider.isPublishing ? null : () => provider.publish(exam),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: provider.isPublishing
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.campaign_rounded),
                label: const Text('Publish Results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishedView extends StatelessWidget {
  final Exam exam;

  const _PublishedView({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF16A34A);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: green.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: green, size: 52),
            ),
            const SizedBox(height: 16),
            Text('Results published.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '${exam.title} results are now visible to students and parents.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Exams'),
            ),
          ],
        ),
      ),
    );
  }
}
