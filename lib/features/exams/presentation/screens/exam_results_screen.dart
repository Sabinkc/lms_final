import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exam_result_provider.dart';
import '../widgets/exam_result_card.dart';

/// docs/screens.md's exam-results view — body adapts by role, same pattern
/// as `AssignmentDetailScreen`: Admin sees the whole class's ranked results
/// + summary, Student sees their own result, Parent picks a child (if more
/// than one) then sees that child's result for this exam.
class ExamResultsScreen extends StatefulWidget {
  final String examId;

  const ExamResultsScreen({super.key, required this.examId});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ExamResultProvider>();
    final authProvider = context.read<AuthProvider>();
    Future.microtask(() {
      switch (authProvider.role) {
        case AppRole.admin:
          provider.loadClassResults(widget.examId);
        case AppRole.student:
          provider.loadMyResultForExam(widget.examId);
        case AppRole.parent:
          provider.loadChildren();
        case AppRole.teacher:
        case null:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Results')),
      body: switch (role) {
        AppRole.admin => _AdminClassResults(examId: widget.examId),
        AppRole.student => _StudentOwnResult(examId: widget.examId),
        AppRole.parent => _ParentChildResult(examId: widget.examId),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _AdminClassResults extends StatelessWidget {
  final String examId;

  const _AdminClassResults({required this.examId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    return switch (provider.classResultsStatus) {
      LoadStatus.initial ||
      LoadStatus.loading => const LoadingView(message: 'Loading results...'),
      LoadStatus.error => ErrorView(
        error: provider.classResultsError!,
        onRetry: () => provider.loadClassResults(examId),
      ),
      LoadStatus.success =>
        provider.classResults.isEmpty
            ? const EmptyStateView(
                message: 'No published results for this exam yet',
              )
            : Column(
                children: [
                  if (provider.classSummary case final summary?)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: StatCardRow(
                        cards: [
                          StatCard(
                            icon: Icons.check_circle_outline,
                            value: '${summary.passed}',
                            label: 'Passed',
                            color: Colors.green,
                          ),
                          StatCard(
                            icon: Icons.cancel_outlined,
                            value: '${summary.failed}',
                            label: 'Failed',
                            color: Theme.of(context).colorScheme.error,
                          ),
                          StatCard(
                            icon: Icons.percent,
                            value: '${summary.avgPercentage}%',
                            label: 'Average',
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: provider.classResults.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final result = provider.classResults[index];
                        final scheme = Theme.of(context).colorScheme;
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: result.rank != null
                                ? CircleAvatar(
                                    backgroundColor: scheme.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    child: Text(
                                      '${result.rank}',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : null,
                            title: Text(
                              result.studentName.isEmpty
                                  ? result.studentAdmissionNumber
                                  : result.studentName,
                            ),
                            subtitle: Text(
                              '${result.grade} · ${result.percentage}%',
                            ),
                            trailing: AppStatusChip(
                              label: result.isPassed ? 'Passed' : 'Failed',
                              color: result.isPassed
                                  ? Colors.green
                                  : scheme.error,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    };
  }
}

class _StudentOwnResult extends StatelessWidget {
  final String examId;

  const _StudentOwnResult({required this.examId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    return switch (provider.myExamResultStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(
        message: 'Loading your result...',
      ),
      LoadStatus.error => ErrorView(
        error: provider.myExamResultError!,
        onRetry: () => provider.loadMyResultForExam(examId),
      ),
      LoadStatus.success => ExamResultCard(result: provider.myExamResult!),
    };
  }
}

class _ParentChildResult extends StatelessWidget {
  final String examId;

  const _ParentChildResult({required this.examId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    return switch (provider.childrenStatus) {
      LoadStatus.initial ||
      LoadStatus.loading => const LoadingView(message: 'Loading children...'),
      LoadStatus.error => ErrorView(
        error: provider.childrenError!,
        onRetry: () => provider.loadChildren(),
      ),
      LoadStatus.success =>
        provider.children.isEmpty
            ? const EmptyStateView(
                message: 'No children linked to your account yet',
              )
            : Column(
                children: [
                  if (provider.children.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppFilterChipBar<String>(
                        options: [
                          for (final child in provider.children) child.id,
                        ],
                        selected:
                            provider.selectedChildId ??
                            provider.children.first.id,
                        labelBuilder: (id) => provider.children
                            .firstWhere((c) => c.id == id)
                            .fullName,
                        onSelected: provider.selectChild,
                      ),
                    ),
                  Expanded(child: _ChildResultBody(examId: examId)),
                ],
              ),
    };
  }
}

class _ChildResultBody extends StatelessWidget {
  final String examId;

  const _ChildResultBody({required this.examId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    if (provider.selectedChildId == null) {
      return const EmptyStateView(
        message: 'Select a child above to view their result',
      );
    }

    return switch (provider.childResultsStatus) {
      LoadStatus.initial ||
      LoadStatus.loading => const LoadingView(message: 'Loading result...'),
      LoadStatus.error => ErrorView(
        error: provider.childResultsError!,
        onRetry: () => provider.selectChild(provider.selectedChildId!),
      ),
      LoadStatus.success => () {
        final forThisExam = provider.childResults.where(
          (r) => r.examId == examId,
        );
        return forThisExam.isEmpty
            ? const EmptyStateView(
                message: 'No published result for this exam yet',
              )
            : ExamResultCard(result: forThisExam.first);
      }(),
    };
  }
}
