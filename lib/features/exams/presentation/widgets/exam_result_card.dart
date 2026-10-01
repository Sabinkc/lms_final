import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/exam_result.dart';

/// Shared single-result display — used by the Student and Parent branches
/// of `ExamResultsScreen`, since both are ultimately "one student's result
/// for one exam" once a child is picked (Parent) or implicitly known
/// (Student).
class ExamResultCard extends StatelessWidget {
  final ExamResult result;

  const ExamResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.35)!],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${result.percentage}%',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Grade ${result.grade}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppStatusChip(
                    label: result.isPassed ? 'Passed' : 'Failed',
                    color: result.isPassed ? Colors.lightGreenAccent.shade700 : Colors.redAccent,
                  ),
                  if (result.rank != null) ...[
                    const SizedBox(height: 6),
                    Text('Rank #${result.rank}', style: const TextStyle(color: Colors.white)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Subject Breakdown', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final mark in result.marks)
                ListTile(
                  dense: true,
                  leading: Icon(
                    mark.isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: mark.isPassed ? Colors.green : scheme.error,
                    size: 20,
                  ),
                  title: Text(mark.subject),
                  subtitle: Text('${mark.obtainedMarks}/${mark.fullMarks}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: AppRadius.button,
                    ),
                    child: Text(mark.grade, style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
            ],
          ),
        ),
        if (result.remarks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Remarks: ${result.remarks}'),
            ),
          ),
        ],
      ],
    );
  }
}
