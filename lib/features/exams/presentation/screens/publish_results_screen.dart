import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/exam.dart';
import '../providers/exam_result_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Publish Results — ${widget.exam.title}'),
        body: switch (provider.rosterStatus) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading roster...'),
          LoadStatus.error => ErrorView(
            error: provider.rosterError!,
            onRetry: () => provider.loadRosterForExam(widget.exam),
          ),
          LoadStatus.success =>
            provider.published
                ? const Center(child: Text('Results published.'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                        child: _ProgressHeader(provider: provider, subjects: widget.exam.subjects),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          itemCount: provider.roster.length,
                          itemBuilder: (context, index) {
                            final student = provider.roster[index];
                            final scheme = Theme.of(context).colorScheme;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                                      ],
                                    ),
                                    for (final subject in widget.exam.subjects)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text('${subject.name} (out of ${subject.fullMarks})')),
                                            SizedBox(
                                              width: 80,
                                              child: TextFormField(
                                                key: ValueKey('${student.id}-${subject.name}'),
                                                decoration: const InputDecoration(labelText: 'Marks'),
                                                keyboardType: TextInputType.number,
                                                onChanged: (value) =>
                                                    provider.setMark(student.id, subject.name, int.tryParse(value)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (provider.publishError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  provider.publishError!.message,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            FilledButton(
                              onPressed: provider.isPublishing ? null : () => provider.publish(widget.exam),
                              child: provider.isPublishing
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Publish Results'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final ExamResultProvider provider;
  final List<ExamSubject> subjects;

  const _ProgressHeader({required this.provider, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var filled = 0;
    final total = provider.roster.length * subjects.length;
    for (final student in provider.roster) {
      for (final subject in subjects) {
        if (provider.markFor(student.id, subject.name) != null) filled++;
      }
    }
    final progress = total == 0 ? 0.0 : filled / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: AppRadius.card),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marks Entered', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: AppRadius.button,
                  child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: scheme.surface),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$filled/$total', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
