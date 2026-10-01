import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../data/models/exam_result.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/exam_result_provider.dart';
import '../widgets/exam_result_card.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Exam Results'),
        body: switch (role) {
          AppRole.admin => _AdminClassResults(examId: widget.examId),
          AppRole.student => _StudentOwnResult(examId: widget.examId),
          AppRole.parent => _ParentChildResult(examId: widget.examId),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _AdminClassResults extends StatefulWidget {
  final String examId;

  const _AdminClassResults({required this.examId});

  @override
  State<_AdminClassResults> createState() => _AdminClassResultsState();
}

class _AdminClassResultsState extends State<_AdminClassResults> {
  final _search = TextEditingController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    return switch (provider.classResultsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading results...'),
      LoadStatus.error => ErrorView(
        error: provider.classResultsError!,
        onRetry: () => provider.loadClassResults(widget.examId),
      ),
      LoadStatus.success =>
        provider.classResults.isEmpty
            ? const EmptyStateView(message: 'No published results for this exam yet')
            : _buildResults(context, provider),
    };
  }

  Widget _buildResults(BuildContext context, ExamResultProvider provider) {
    final results = provider.classResults;
    final passed = results.where((r) => r.isPassed).length;
    final query = _search.text.trim().toLowerCase();
    final visible = results.where((r) {
      if (_filter == 'Passed' && !r.isPassed) return false;
      if (_filter == 'Failed' && r.isPassed) return false;
      return query.isEmpty ||
          r.studentName.toLowerCase().contains(query) ||
          r.studentAdmissionNumber.toLowerCase().contains(query);
    }).toList();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        if (provider.classSummary case final summary?) ...[
          Row(
            children: [
              Expanded(
                child: TintedStatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Passed',
                  value: '${summary.passed}',
                  caption: summary.total > 0 ? '${(summary.passed * 100 / summary.total).round()}% of class' : null,
                  color: _passGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TintedStatTile(
                  icon: Icons.cancel_outlined,
                  label: 'Failed',
                  value: '${summary.failed}',
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TintedStatTile(
                  icon: Icons.percent,
                  label: 'Average',
                  value: '${summary.avgPercentage}%',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search student name or admission no...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        AppFilterChipBar<String>(
          options: const ['All', 'Passed', 'Failed'],
          selected: _filter,
          labelBuilder: (o) => o,
          countBuilder: (o) => switch (o) {
            'Passed' => passed,
            'Failed' => results.length - passed,
            _ => results.length,
          },
          onSelected: (o) => setState(() => _filter = o),
        ),
        const SizedBox(height: 14),
        Text(
          'Student Rankings & Marks',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyStateView(message: 'No students match your search', icon: Icons.search_off),
          ),
        for (final result in visible) ...[
          _RankedResultCard(result: result),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

const _passGreen = Color(0xFF16A34A);

/// Gold / silver / bronze for the top three ranks, none otherwise.
Color? _medalColor(int? rank) => switch (rank) {
      1 => const Color(0xFFEAB308),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFD97706),
      _ => null,
    };

class _RankedResultCard extends StatelessWidget {
  final ExamResult result;

  const _RankedResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = _medalColor(result.rank);
    final name = result.studentName.isEmpty ? result.studentAdmissionNumber : result.studentName;
    final statusColor = result.isPassed ? _passGreen : AppColors.danger;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: medal != null ? BorderSide(color: medal.withValues(alpha: 0.5)) : BorderSide.none,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (medal != null) Container(width: 5, color: medal),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              if (result.studentAdmissionNumber.isNotEmpty && result.studentName.isNotEmpty)
                                Text(
                                  result.studentAdmissionNumber,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (result.rank != null)
                          AppStatusPill(
                            label: 'Rank #${result.rank}',
                            icon: medal != null ? Icons.emoji_events_rounded : null,
                            color: medal ?? theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        AppStatusPill(label: 'Grade ${result.grade}', color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('${result.percentage}%', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        AppStatusPill(label: result.isPassed ? 'Passed' : 'Failed', color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result.totalObtained} / ${result.totalFull} marks',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentOwnResult extends StatelessWidget {
  final String examId;

  const _StudentOwnResult({required this.examId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamResultProvider>();

    return switch (provider.myExamResultStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading your result...'),
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
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading children...'),
      LoadStatus.error => ErrorView(error: provider.childrenError!, onRetry: () => provider.loadChildren()),
      LoadStatus.success =>
        provider.children.isEmpty
            ? const EmptyStateView(message: 'No children linked to your account yet')
            : Column(
                children: [
                  if (provider.children.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppFilterChipBar<String>(
                        options: [for (final child in provider.children) child.id],
                        selected: provider.selectedChildId ?? provider.children.first.id,
                        labelBuilder: (id) => provider.children.firstWhere((c) => c.id == id).fullName,
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
      return const EmptyStateView(message: 'Select a child above to view their result');
    }

    return switch (provider.childResultsStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading result...'),
      LoadStatus.error => ErrorView(
        error: provider.childResultsError!,
        onRetry: () => provider.selectChild(provider.selectedChildId!),
      ),
      LoadStatus.success => () {
        final forThisExam = provider.childResults.where((r) => r.examId == examId);
        return forThisExam.isEmpty
            ? const EmptyStateView(message: 'No published result for this exam yet')
            : ExamResultCard(result: forThisExam.first);
      }(),
    };
  }
}
