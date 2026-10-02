import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
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
import '../../data/models/exam.dart';
import '../providers/exam_provider.dart';
import 'exam_form_dialog.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md's Exam & Academic Schedule module. One list for every
/// role (`GET /exams` Admin-only, `GET /exams/my` everyone else, role read
/// inside the initState microtask — same reasoning as
/// `AssignmentDetailScreen`/`NoticesListScreen`). Each card shows its
/// subjects inline rather than navigating to a separate detail screen —
/// `examController` has no `GET /:id` for non-Admin roles, so there's
/// nothing to re-fetch anyway; the already-loaded list item is the detail.
/// Layout follows the Stitch `cloudslms_exams` mockup: summary tiles,
/// search, status chips, then one rich card per exam.
class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  final _search = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExamProvider>();
    final authProvider = context.read<AuthProvider>();
    _search.addListener(() => setState(() {}));
    Future.microtask(() {
      if (authProvider.role == AppRole.admin) {
        provider.loadExamsAsAdmin();
      } else {
        provider.loadMyExams();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<ExamProvider>();
    await (context.read<AuthProvider>().role == AppRole.admin
        ? provider.loadExamsAsAdmin(silent: true)
        : provider.loadMyExams(silent: true));
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
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.status) {
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
                  : _buildList(context, provider.exams, role, isAdmin),
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Exam> exams, AppRole? role, bool isAdmin) {
    final counts = <String, int>{};
    for (final e in exams) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }
    final statuses = [
      for (final s in _statusOrder)
        if (counts.containsKey(s)) s,
    ];
    final status = statuses.contains(_status) ? _status : null;
    final query = _search.text.trim().toLowerCase();
    final visible = exams.where((e) {
      if (status != null && e.status != status) return false;
      if (query.isEmpty) return true;
      return e.title.toLowerCase().contains(query) ||
          e.className.toLowerCase().contains(query) ||
          e.subjects.any((s) => s.name.toLowerCase().contains(query));
    }).toList();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.assignment_outlined,
                label: 'Total Exams',
                value: '${exams.length}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.event_outlined,
                label: 'Upcoming',
                value: '${(counts['upcoming'] ?? 0) + (counts['ongoing'] ?? 0)}',
                color: _statusStyle('upcoming').color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.verified_outlined,
                label: 'Published',
                value: '${counts['published'] ?? 0}',
                color: _statusStyle('published').color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search exams, subjects, classes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        AppFilterChipBar<String?>(
          options: [null, ...statuses],
          selected: status,
          labelBuilder: (s) => s == null ? 'All' : _statusStyle(s).label,
          countBuilder: (s) => s == null ? exams.length : counts[s]!,
          onSelected: (s) => setState(() => _status = s),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: EmptyStateView(message: 'No exams match your search', icon: Icons.search_off),
          ),
        for (final exam in visible) ...[
          _ExamCard(exam: exam, role: role, isAdmin: isAdmin),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

const _statusOrder = ['upcoming', 'ongoing', 'completed', 'published'];

({String label, IconData icon, Color color}) _statusStyle(String status) => switch (status) {
  'published' => (label: 'Published', icon: Icons.check_circle_outline, color: AppColors.success),
  'ongoing' => (label: 'In Progress', icon: Icons.timelapse, color: AppColors.warning),
  'completed' => (label: 'Completed', icon: Icons.pending_actions, color: AppColors.teal),
  _ => (label: 'Upcoming', icon: Icons.schedule, color: AppColors.slate),
};

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final AppRole? role;
  final bool isAdmin;

  const _ExamCard({required this.exam, required this.role, required this.isAdmin});

  /// "12 Sep 2026" or "12 Sep 2026 – 18 Sep 2026" across the subject dates,
  /// falling back to the exam's own date.
  String get _dateRange {
    final dates = [
      for (final s in exam.subjects)
        if (s.examDate.isNotEmpty) s.examDate,
    ]..sort();
    if (dates.isEmpty || dates.first == dates.last) {
      return formatDisplayDate(dates.isEmpty ? exam.examDate : dates.first);
    }
    return '${formatDisplayDate(dates.first)} – ${formatDisplayDate(dates.last)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _statusStyle(exam.status);
    final totalMarks = exam.subjects.fold<int>(0, (sum, s) => sum + s.fullMarks);
    final actions = _actions(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(Icons.history_edu_rounded, color: context.readable(AppColors.info)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${exam.className}${exam.section != null ? ' · Section ${exam.section}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppStatusPill(label: style.label, icon: style.icon, color: style.color),
              ],
            ),
            const SizedBox(height: 12),
            InfoStrip(
              icon: Icons.calendar_today_outlined,
              text: _dateRange,
              trailing: totalMarks > 0 ? '$totalMarks Total Marks' : null,
            ),
            if (exam.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(children: [for (final subject in exam.subjects) _SubjectRow(subject: subject)]),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    void results() => context.push(AppRoutes.examResults(exam.id));
    final published = exam.status == 'published';
    return [
      if (isAdmin && !published)
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.examPublishResults(exam.id), extra: exam),
          icon: const Icon(Icons.publish_rounded, size: 18),
          label: const Text('Publish Results'),
        ),
      if (isAdmin && published)
        FilledButton.tonalIcon(
          onPressed: results,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('View Results'),
        ),
      if (!isAdmin && role == AppRole.student)
        FilledButton.tonalIcon(
          onPressed: results,
          icon: const Icon(Icons.grading_rounded, size: 18),
          label: const Text('My Result'),
        ),
      if (role == AppRole.parent)
        FilledButton.tonalIcon(
          onPressed: results,
          icon: const Icon(Icons.grading_rounded, size: 18),
          label: const Text("Child's Result"),
        ),
    ];
  }
}

class _SubjectRow extends StatelessWidget {
  final ExamSubject subject;

  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final when = [
      if (subject.examDate.isNotEmpty) formatDisplayDate(subject.examDate),
      ?subject.examTime,
      if (subject.room != null) 'Room ${subject.room}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (when.isNotEmpty) Text(when, style: muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${subject.fullMarks} marks',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.readable(AppColors.primary),
                ),
              ),
              Text('Pass ${subject.passMarks}', style: muted),
            ],
          ),
        ],
      ),
    );
  }
}
