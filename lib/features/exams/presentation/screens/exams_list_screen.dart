import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exam.dart';
import '../providers/exam_provider.dart';
import 'exam_form_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Exams'),
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
          LoadStatus.success =>
            provider.exams.isEmpty
                ? EmptyStateView(
                    message: 'No exams scheduled yet',
                    icon: Icons.school_outlined,
                    actionLabel: isAdmin ? 'Add Exam' : null,
                    onAction: isAdmin ? () => showExamFormDialog(context, provider) : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    itemCount: provider.exams.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _ExamTile(exam: provider.exams[index], role: role, isAdmin: isAdmin),
                  ),
        },
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.14), borderRadius: AppRadius.card),
          child: Icon(Icons.school_outlined, color: scheme.primary, size: 20),
        ),
        title: Text(exam.title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '${exam.className}${exam.section != null ? ' ${exam.section}' : ''} · Due ${formatDisplayDate(exam.examDate)}',
              ),
              if (exam.status == 'published') const AppStatusChip(label: 'Published', color: Colors.green),
            ],
          ),
        ),
        children: [
          for (final subject in exam.subjects)
            ListTile(
              dense: true,
              leading: Icon(Icons.menu_book_outlined, color: scheme.onSurfaceVariant, size: 18),
              title: Text(subject.name),
              subtitle: Text(
                '${formatDisplayDate(subject.examDate)}${subject.examTime != null ? ' at ${subject.examTime}' : ''}'
                '${subject.room != null ? ' · Room ${subject.room}' : ''}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadius.button,
                ),
                child: Text('${subject.fullMarks} marks', style: Theme.of(context).textTheme.labelSmall),
              ),
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
      ),
    );
  }
}
