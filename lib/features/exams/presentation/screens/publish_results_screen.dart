import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/exam.dart';
import '../providers/exam_result_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text('Publish Results — ${widget.exam.title}')),
      body: switch (provider.rosterStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading roster...'),
        LoadStatus.error => ErrorView(
            error: provider.rosterError!,
            onRetry: () => provider.loadRosterForExam(widget.exam),
          ),
        LoadStatus.success => provider.published
            ? const Center(child: Text('Results published.'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.roster.length,
                      itemBuilder: (context, index) {
                        final student = provider.roster[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
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
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Publish Results'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      },
    );
  }
}
