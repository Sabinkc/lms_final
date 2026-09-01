import 'package:flutter/material.dart';

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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(result.grade, style: Theme.of(context).textTheme.headlineMedium),
                Text('${result.percentage}%'),
              ],
            ),
            Text(result.isPassed ? 'Passed' : 'Failed'),
            if (result.rank != null) Text('Rank: ${result.rank}'),
            const Divider(),
            for (final mark in result.marks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mark.subject),
                    Text('${mark.obtainedMarks}/${mark.fullMarks} (${mark.grade})'),
                  ],
                ),
              ),
            if (result.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Remarks: ${result.remarks}'),
            ],
          ],
        ),
      ),
    );
  }
}
