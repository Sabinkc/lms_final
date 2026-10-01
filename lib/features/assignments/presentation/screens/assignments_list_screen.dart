import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/assignment.dart';
import '../providers/assignment_provider.dart';
import 'assignment_form_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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
  final _searchController = TextEditingController();
  String _search = '';
  String _subjectFilter = 'All';

  @override
  void initState() {
    super.initState();
    final provider = context.read<AssignmentProvider>();
    Future.microtask(() => provider.loadAssignments());
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Assignment> _filtered(List<Assignment> assignments) {
    return assignments.where((a) {
      final matchesSubject = _subjectFilter == 'All' || a.subject == _subjectFilter;
      final matchesSearch =
          _search.isEmpty ||
          a.title.toLowerCase().contains(_search) ||
          a.subject.toLowerCase().contains(_search) ||
          a.className.toLowerCase().contains(_search);
      return matchesSubject && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssignmentProvider>();
    final role = context.watch<AuthProvider>().role;
    final isTeacher = role == AppRole.teacher;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Assignments'),
        floatingActionButton: isTeacher
            ? FloatingActionButton(
                onPressed: () => showAssignmentFormDialog(context, provider),
                tooltip: 'Add Assignment',
                child: const Icon(Icons.add),
              )
            : null,
        body: switch (provider.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading assignments...'),
          LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadAssignments()),
          LoadStatus.success => _buildList(context, provider, isTeacher),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, AssignmentProvider provider, bool isTeacher) {
    if (provider.assignments.isEmpty) {
      return EmptyStateView(
        message: 'No assignments yet',
        icon: Icons.assignment_outlined,
        actionLabel: isTeacher ? 'Add Assignment' : null,
        onAction: isTeacher ? () => showAssignmentFormDialog(context, provider) : null,
      );
    }

    final subjects = <String>{'All', ...provider.assignments.map((a) => a.subject).where((s) => s.isNotEmpty)}.toList();
    final filtered = _filtered(provider.assignments);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search assignments or classes...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: AppFilterChipBar<String>(
            options: subjects,
            selected: _subjectFilter,
            onSelected: (value) => setState(() => _subjectFilter = value),
            labelBuilder: (value) => value,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateView(message: 'No assignments match your search', icon: Icons.search_off)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _AssignmentCard(assignment: filtered[index], isTeacher: isTeacher, provider: provider),
                ),
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool isTeacher;
  final AssignmentProvider provider;

  const _AssignmentCard({required this.assignment, required this.isTeacher, required this.provider});

  IconData get _subjectIcon {
    final subject = assignment.subject.toLowerCase();
    if (subject.contains('math')) return Icons.calculate_outlined;
    if (subject.contains('science') || subject.contains('physics') || subject.contains('chemistry')) {
      return Icons.science_outlined;
    }
    if (subject.contains('english') || subject.contains('literature')) return Icons.menu_book_outlined;
    if (subject.contains('history') || subject.contains('social')) return Icons.public_outlined;
    if (subject.contains('art')) return Icons.palette_outlined;
    if (subject.contains('computer') || subject.contains('ict')) return Icons.computer_outlined;
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.assignmentDetail(assignment.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.14), borderRadius: AppRadius.card),
                child: Icon(_subjectIcon, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            assignment.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _RowTrailing(assignment: assignment, isTeacher: isTeacher, provider: provider),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${assignment.subject} · ${assignment.className} ${assignment.section} · Due ${formatDisplayDate(assignment.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowTrailing extends StatelessWidget {
  final Assignment assignment;
  final bool isTeacher;
  final AssignmentProvider provider;

  const _RowTrailing({required this.assignment, required this.isTeacher, required this.provider});

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
          onPressed: () => showAssignmentFormDialog(context, provider, existing: assignment),
        ),
      ],
    );
  }
}
