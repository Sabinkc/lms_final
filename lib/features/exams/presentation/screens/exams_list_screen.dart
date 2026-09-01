import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exam.dart';
import '../providers/exam_provider.dart';
import 'exam_form_dialog.dart';

/// docs/screens.md's Exam & Academic Schedule module. One list for every
/// role (`GET /exams` Admin-only, `GET /exams/my` everyone else, role read
/// inside the initState microtask — same reasoning as
/// `AssignmentDetailScreen`/`NoticesListScreen`). Each row expands in place
/// to show its subjects rather than navigating to a separate detail
/// screen — `examController` has no `GET /:id` for non-Admin roles, so
/// there's nothing to re-fetch anyway; the already-loaded list item is the
/// detail.
class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ExamProvider>();
    final authProvider = context.read<AuthProvider>();
    Future.microtask(() {
      if (authProvider.role == AppRole.admin) {
        provider.loadExamsAsAdmin();
      } else {
        provider.loadMyExams();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamProvider>();
    final role = context.watch<AuthProvider>().role;
    final isAdmin = role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Exams')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => showExamFormDialog(context, provider),
              tooltip: 'Add Exam',
              child: const Icon(Icons.add),
            )
          : null,
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading exams...'),
        LoadStatus.error => ErrorView(
            error: provider.error!,
            onRetry: () => isAdmin ? provider.loadExamsAsAdmin() : provider.loadMyExams(),
          ),
        LoadStatus.success => provider.exams.isEmpty
            ? EmptyStateView(
                message: 'No exams scheduled yet',
                icon: Icons.school_outlined,
                actionLabel: isAdmin ? 'Add Exam' : null,
                onAction: isAdmin ? () => showExamFormDialog(context, provider) : null,
              )
            : ListView.builder(
                itemCount: provider.exams.length,
                itemBuilder: (context, index) => _ExamTile(exam: provider.exams[index], role: role, isAdmin: isAdmin),
              ),
      },
    );
  }
}

class _ExamTile extends StatelessWidget {
  final Exam exam;
  final AppRole? role;
  final bool isAdmin;

  const _ExamTile({required this.exam, required this.role, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(exam.title),
      subtitle: Text(
        'Class ${exam.className}${exam.section != null ? ' ${exam.section}' : ''} · Due ${exam.examDate}'
        '${exam.status == 'published' ? ' · Published' : ''}',
      ),
      children: [
        for (final subject in exam.subjects)
          ListTile(
            dense: true,
            title: Text(subject.name),
            subtitle: Text('${subject.examDate}${subject.examTime != null ? ' at ${subject.examTime}' : ''}'
                '${subject.room != null ? ' · Room ${subject.room}' : ''}'),
            trailing: Text('${subject.fullMarks} marks'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              if (isAdmin && exam.status != 'published')
                FilledButton(
                  onPressed: () => context.push(AppRoutes.examPublishResults(exam.id), extra: exam),
                  child: const Text('Publish Results'),
                ),
              if (isAdmin && exam.status == 'published')
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.examResults(exam.id)),
                  child: const Text('View Results'),
                ),
              if (!isAdmin && role == AppRole.student)
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.examResults(exam.id)),
                  child: const Text('My Result'),
                ),
              if (role == AppRole.parent)
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.examResults(exam.id)),
                  child: const Text("Child's Result"),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
