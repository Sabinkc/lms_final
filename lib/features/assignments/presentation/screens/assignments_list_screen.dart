import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/subject_icon.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/assignment.dart';
import '../providers/assignment_provider.dart';
import 'assignment_form_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

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

  Future<void> _refresh() async {
    await context.read<AssignmentProvider>().loadAssignments(silent: true);
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
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.status) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading assignments...'),
            // The backend's `GET /api/assignments` only runs `protect`, which
            // never sets `req.admin`, so its "admin → whole school" branch is
            // dead and every Admin gets a 403 (`assignmentController.js`
            // getAllAssignments; same root cause as the delete bug in
            // docs/api_spec.md §12 #7). Explain that instead of offering a
            // Retry that can never succeed.
            LoadStatus.error when role == AppRole.admin && provider.error is ForbiddenException => const EmptyStateView(
              message:
                  'Assignments are created and graded by teachers. The server does not yet let Admin accounts view them.',
              icon: Icons.lock_outline_rounded,
            ),
            LoadStatus.error => ErrorView(error: provider.error!, onRetry: () => provider.loadAssignments()),
            LoadStatus.success => _buildList(context, provider, isTeacher),
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AssignmentProvider provider, bool isTeacher) {
    final all = provider.assignments;
    if (all.isEmpty) {
      return EmptyStateView(
        message: 'No assignments yet',
        icon: Icons.assignment_outlined,
        actionLabel: isTeacher ? 'Add Assignment' : null,
        onAction: isTeacher ? () => showAssignmentFormDialog(context, provider) : null,
      );
    }

    final subjectCounts = <String, int>{};
    for (final a in all) {
      if (a.subject.isNotEmpty) subjectCounts[a.subject] = (subjectCounts[a.subject] ?? 0) + 1;
    }
    final subjects = ['All', ...subjectCounts.keys];
    final filtered = _filtered(all);
    final now = DateTime.now();
    final open = all.where((a) => a.status != 'closed').toList();
    final dueSoon = open.where((a) {
      final due = DateTime.tryParse(a.dueDate)?.toLocal();
      return due != null && !due.isBefore(now) && due.difference(now).inDays < 7;
    }).length;
    final overdue = open.where((a) => DateTime.tryParse(a.dueDate)?.toLocal().isBefore(now) ?? false).length;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.assignment_outlined,
                label: 'Active',
                value: '${open.length}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Due in 7 days',
                value: '$dueSoon',
                color: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.event_busy_outlined,
                label: 'Past due',
                value: '$overdue',
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search assignments or classes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        AppFilterChipBar<String>(
          options: subjects,
          selected: subjects.contains(_subjectFilter) ? _subjectFilter : 'All',
          onSelected: (value) => setState(() => _subjectFilter = value),
          labelBuilder: (value) => value,
          countBuilder: (value) => value == 'All' ? all.length : subjectCounts[value]!,
          iconBuilder: (value) => value == 'All' ? null : subjectIcon(value),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: EmptyStateView(message: 'No assignments match your search', icon: Icons.search_off),
          ),
        for (final assignment in filtered) ...[
          _AssignmentCard(assignment: assignment, isTeacher: isTeacher, provider: provider),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// "Due today", "Due in 3 days", "2 days overdue" from an ISO due date.
String? _relativeDue(String raw, DateTime now) {
  final due = DateTime.tryParse(raw)?.toLocal();
  if (due == null) return null;
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  if (days > 1) return 'Due in $days days';
  return days == -1 ? '1 day overdue' : '${-days} days overdue';
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool isTeacher;
  final AssignmentProvider provider;

  const _AssignmentCard({required this.assignment, required this.isTeacher, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = assignment.status == 'closed';
    final relative = _relativeDue(assignment.dueDate, DateTime.now());
    final overdue = !closed && (relative?.endsWith('overdue') ?? false);
    final accent = closed ? Colors.grey : (overdue ? AppColors.danger : AppColors.primary);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.assignmentDetail(assignment.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(subjectIcon(assignment.subject), color: context.readable(AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${assignment.subject} · ${assignment.className} ${assignment.section} · Due ${formatDisplayDate(assignment.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _RowTrailing(assignment: assignment, isTeacher: isTeacher, provider: provider),
                ],
              ),
              if (assignment.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  assignment.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              InfoStrip(
                icon: closed ? Icons.lock_outline : Icons.schedule_rounded,
                text: closed ? 'Closed for submissions' : (relative ?? 'Due ${formatDisplayDate(assignment.dueDate)}'),
                trailing: assignment.attachment.isNotEmpty ? 'Attachment' : null,
                color: accent,
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
    final closed = assignment.status == 'closed';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (closed)
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: AppStatusPill(label: 'Closed', icon: Icons.lock_outline, color: Colors.grey),
          ),
        if (isTeacher)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            onPressed: () => showAssignmentFormDialog(context, provider, existing: assignment),
          ),
      ],
    );
  }
}
