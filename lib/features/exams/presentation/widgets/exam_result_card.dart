import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../data/models/exam_result.dart';
import '../../../../core/theme/readable_color.dart';

/// Shared single-result display — used by the Student and Parent branches
/// of `ExamResultsScreen`, since both are ultimately "one student's result
/// for one exam" once a child is picked (Parent) or implicitly known
/// (Student). Layout follows the Stitch `cloudslms_exam_results_student_parent`
/// mockup: overall hero with a grade ring, three key tiles, then one card
/// per subject with a score bar.
class ExamResultCard extends StatelessWidget {
  final ExamResult result;

  const ExamResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passColor = result.isPassed ? AppColors.success : AppColors.danger;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        if (result.examTitle.isNotEmpty) ...[
          Text(result.examTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
        ],
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL RESULT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${result.percentage}%',
                          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Grade ${result.grade}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.totalObtained}/${result.totalFull} marks',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              _GradeRing(grade: result.grade, fraction: result.percentage / 100),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.functions_rounded,
                label: 'Total Marks',
                value: '${result.totalObtained}',
                caption: 'of ${result.totalFull}',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.emoji_events_outlined,
                label: 'Class Rank',
                value: result.rank != null ? '#${result.rank}' : '—',
                color: AppColors.ochre,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: result.isPassed ? Icons.verified_outlined : Icons.cancel_outlined,
                label: 'Status',
                value: result.isPassed ? 'Pass' : 'Fail',
                color: passColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: passColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xl4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(result.isPassed ? Icons.check_circle : Icons.cancel, size: 18, color: context.readable(passColor)),
              const SizedBox(width: 6),
              Text(
                result.isPassed ? 'Passed' : 'Failed',
                style: TextStyle(color: context.readable(passColor), fontWeight: FontWeight.w700),
              ),
              if (result.rank != null) ...[
                Text('  ·  ', style: TextStyle(color: context.readable(passColor))),
                Text(
                  'Rank #${result.rank}',
                  style: TextStyle(color: context.readable(passColor), fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Subject-wise Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${result.marks.length} Subjects',
              style: theme.textTheme.labelMedium?.copyWith(color: context.readable(AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final mark in result.marks) ...[_SubjectMarkCard(mark: mark), const SizedBox(height: 10)],
        if (result.remarks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            icon: Icons.rate_review_outlined,
            title: 'Remarks',
            child: Text(result.remarks, style: theme.textTheme.bodyMedium),
          ),
        ],
      ],
    );
  }
}

class _GradeRing extends StatelessWidget {
  final String grade;
  final double fraction;

  const _GradeRing({required this.grade, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: fraction.clamp(0, 1),
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          Center(
            child: Text(
              grade,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMarkCard extends StatelessWidget {
  final ExamResultMark mark;

  const _SubjectMarkCard({required this.mark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = mark.isPassed ? AppColors.primary : AppColors.danger;
    final fraction = mark.fullMarks == 0 ? 0.0 : mark.obtainedMarks / mark.fullMarks;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mark.subject, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Grade ${mark.grade}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.readable(color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${mark.obtainedMarks}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: ' /${mark.fullMarks}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    AppStatusPill(label: mark.isPassed ? 'Pass' : 'Fail', color: color),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: 7,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pass mark ${mark.passMarks}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Text(
                  '${(fraction * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.readable(color),
                    fontWeight: FontWeight.w700,
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
