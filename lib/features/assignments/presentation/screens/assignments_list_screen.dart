import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/assignment.dart';
import '../providers/assignment_provider.dart';
import 'assignment_form_dialog.dart';

/// docs/screens.md's Assignments module, System A
/// (`docs/production_roadmap.md` §4 decision #3). One list for every role —
/// `GET /api/assignments` is scoped entirely server-side (Teacher → own,
/// Student → own class's active ones, Parent → union of children's classes'
/// active ones, Admin → whole school) — only the FAB (Teacher-only, to
/// create) and each row's affordances differ by role.
class AssignmentsListScreen extends StatefulWidget {
  const AssignmentsListScreen({super.key});

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AssignmentProvider>();
    Future.microtask(() => provider.loadAssignments());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final role = context.watch<AuthProvider>().role;
    final isTeacher = role == AppRole.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => showAssignmentFormDialog(context, provider),
              tooltip: 'Add Assignment',
              child: const Icon(Icons.add),
            )
          : null,
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(
          message: 'Loading assignments...',
        ),
        LoadStatus.error => ErrorView(
          error: provider.error!,
          onRetry: () => provider.loadAssignments(),
        ),
        LoadStatus.success =>
          provider.assignments.isEmpty
              ? EmptyStateView(
                  message: 'No assignments yet',
                  icon: Icons.assignment_outlined,
                  actionLabel: isTeacher ? 'Add Assignment' : null,
                  onAction: isTeacher
                      ? () => showAssignmentFormDialog(context, provider)
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: provider.assignments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final assignment = provider.assignments[index];
                    final scheme = Theme.of(context).colorScheme;
                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.14),
                            borderRadius: AppRadius.card,
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        title: Text(
                          assignment.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${assignment.subject} · ${assignment.className} ${assignment.section} · Due ${formatDisplayDate(assignment.dueDate)}',
                        ),
                        trailing: _RowTrailing(
                          assignment: assignment,
                          isTeacher: isTeacher,
                          provider: provider,
                        ),
                        onTap: () => context.push(
                          AppRoutes.assignmentDetail(assignment.id),
                        ),
                      ),
                    );
                  },
                ),
      },
    );
  }
}

class _RowTrailing extends StatelessWidget {
  final Assignment assignment;
  final bool isTeacher;
  final AssignmentProvider provider;

  const _RowTrailing({
    required this.assignment,
    required this.isTeacher,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTeacher) {
      return assignment.status == 'closed'
          ? const AppStatusChip(label: 'Closed', color: Colors.grey)
          : const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assignment.status == 'closed')
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: AppStatusChip(label: 'Closed', color: Colors.grey),
          ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () =>
              showAssignmentFormDialog(context, provider, existing: assignment),
        ),
      ],
    );
  }
}
