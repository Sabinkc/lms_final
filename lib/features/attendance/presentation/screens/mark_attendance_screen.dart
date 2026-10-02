import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_status.dart';
import '../../data/models/teacher_section.dart';
import '../../../admin_management/presentation/widgets/class_badge.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_status_style.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// Weekday deliberately dropped from the reference's "Thu, 16 Apr 2025"
// format — at a real device's AppBar width, that plus the "Attendance"
// title truncated the title to "Attenda…"; this shorter form leaves it
// room to render in full.
String _formatDatePill(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// docs/screens.md "Mark Attendance" (Teacher). Locks immediately on submit
/// — confirmed no Teacher-facing edit path exists afterward
/// (`implementation_backlog.md` E3-F1-T4) — so a successful submit disables
/// further edits on this screen rather than leaving it re-submittable.
///
/// Restyled 2026-09-28 to match a reference design the user supplied
/// (`LMS UI/WhatsApp Image ... 3.49.18 PM.jpeg`) "where possible" — its
/// per-student avatar+pill roster and stat-card row map directly onto this
/// screen's existing roster/StatCardRow; its "View Class" button and photo
/// avatars don't (no class-detail destination or student photos exist in
/// this app), so those were left out rather than faked. The always-visible
/// 5-way status `Wrap` was replaced with a single colored status pill
/// (`_StatusPill`) that opens the same 5 choices in a popup — keeps full
/// edit capability while matching the reference's one-pill-per-row look.
class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _subjectController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    Future.microtask(() => provider.loadMySections());
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    TeacherSection? selectedSection;
    if (_selectedSectionId != null) {
      for (final s in provider.sections) {
        if (s.id == _selectedSectionId) {
          selectedSection = s;
          break;
        }
      }
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          // Shortened from "Mark Attendance" — that plus the date pill (now
          // in `actions`, matching the reference's top-right date picker)
          // truncated to "Mark Att…" at real device width; "Attendance"
          // alone also matches the reference's own AppBar title exactly.
          title: 'Attendance',
          // The date pill already fills the right side — the avatar menu on
          // top would truncate the title again at phone width.
          showAccount: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(_formatDatePill(_date)),
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      switch (provider.sectionsStatus) {
                        LoadStatus.initial || LoadStatus.loading => const LinearProgressIndicator(),
                        LoadStatus.error => Text(
                          provider.sectionsError!.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        LoadStatus.success => DropdownButtonFormField<String>(
                          initialValue: _selectedSectionId,
                          decoration: const InputDecoration(labelText: 'Section'),
                          items: [
                            for (final s in provider.sections)
                              DropdownMenuItem(value: s.id, child: Text('${s.className} — ${s.name}')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedSectionId = value);
                            if (value != null) provider.loadRoster(value);
                          },
                        ),
                      },
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(labelText: 'Subject (optional)', hintText: 'General'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selectedSection != null) _ClassSummaryCard(section: selectedSection),
            Expanded(child: _RosterBody(sectionId: _selectedSectionId)),
          ],
        ),
        bottomNavigationBar: _selectedSectionId == null || provider.rosterStatus != LoadStatus.success
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SubmitBar(sectionId: _selectedSectionId!, date: _date, subjectController: _subjectController),
                ),
              ),
      ),
    );
  }
}

/// The "Grade 10 / Science • Section A" identity card from the reference —
/// no per-department data exists on [TeacherSection], so the subtitle is
/// just the real section name rather than a fabricated stream/department.
class _ClassSummaryCard extends StatelessWidget {
  final TeacherSection section;

  const _ClassSummaryCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.slate.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            ClassBadge(name: section.className, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.className, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    'Section ${section.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterBody extends StatefulWidget {
  final String? sectionId;

  const _RosterBody({required this.sectionId});

  @override
  State<_RosterBody> createState() => _RosterBodyState();
}

class _RosterBodyState extends State<_RosterBody> {
  final _searchController = TextEditingController();
  String _query = '';
  AttendanceStatus? _filter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (widget.sectionId == null) {
      return const EmptyStateView(message: 'Pick a section to load its roster', icon: Icons.groups_outlined);
    }

    return switch (provider.rosterStatus) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading roster...'),
      LoadStatus.error => ErrorView(
        error: provider.rosterError!,
        onRetry: () => provider.loadRoster(widget.sectionId!),
      ),
      LoadStatus.success =>
        provider.roster.isEmpty
            ? const EmptyStateView(message: 'No students in this section')
            : _RosterList(
                roster: provider.roster,
                searchController: _searchController,
                query: _query,
                onQueryChanged: (value) => setState(() => _query = value),
                filter: _filter,
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
    };
  }
}

class _RosterList extends StatelessWidget {
  final List<Student> roster;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final AttendanceStatus? filter;
  final ValueChanged<AttendanceStatus?> onFilterChanged;

  const _RosterList({
    required this.roster,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final locked = provider.lastSubmitResult != null;
    final scheme = Theme.of(context).colorScheme;

    final present = roster.where((s) => provider.statusFor(s.id) == AttendanceStatus.present).length;
    final absent = roster.where((s) => provider.statusFor(s.id) == AttendanceStatus.absent).length;
    final lateCount = roster.where((s) => provider.statusFor(s.id) == AttendanceStatus.late).length;

    final visible = roster.where((s) {
      final matchesQuery = query.isEmpty || s.fullName.toLowerCase().contains(query.toLowerCase());
      final matchesFilter = filter == null || provider.statusFor(s.id) == filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.groups_rounded,
                label: 'Total',
                value: '${roster.length}',
                caption: 'students',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            for (final (status, n) in [
              (AttendanceStatus.present, present),
              (AttendanceStatus.absent, absent),
              (AttendanceStatus.late, lateCount),
            ]) ...[
              Expanded(
                child: TintedStatTile(
                  icon: attendanceStatusStyle(status.apiValue, scheme).$2,
                  label: status.label,
                  value: '$n',
                  caption: '(${roster.isEmpty ? 0 : (n / roster.length * 100).toStringAsFixed(1)}%)',
                  color: attendanceStatusStyle(status.apiValue, scheme).$3,
                ),
              ),
              if (status != AttendanceStatus.late) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search student...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<AttendanceStatus?>(
              tooltip: 'Filter by status',
              initialValue: filter,
              onSelected: onFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('All')),
                for (final status in AttendanceStatus.values) PopupMenuItem(value: status, child: Text(status.label)),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: AppRadius.button,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(filter?.label ?? 'All'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!locked)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                for (final student in roster) {
                  provider.setStatus(student.id, AttendanceStatus.present);
                }
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark All Present'),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
            child: Center(child: Text('No students match this search/filter.')),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  _RosterCard(student: visible[i], locked: locked),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RosterCard extends StatelessWidget {
  final Student student;
  final bool locked;

  const _RosterCard({required this.student, required this.locked});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final current = provider.statusFor(student.id);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            foregroundColor: scheme.primary,
            child: Text(initialsFor(student.fullName), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    '${student.className} • Section ${student.section}',
                    if (student.rollNumber.isNotEmpty) 'Roll ${student.rollNumber}',
                  ].join('  •  '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusPill(current: current, locked: locked, onChanged: (status) => provider.setStatus(student.id, status)),
        ],
      ),
    );
  }
}

/// A single colored status pill (the reference's per-row "Present"/"Absent"
/// badge) that opens a popup menu with all 5 [AttendanceStatus] values when
/// tapped — replaces the previous always-expanded 5-`ChoiceChip` `Wrap` so
/// the row matches the reference's one-badge look without losing the
/// ability to pick Late/Leave/Half-day, which the reference's two-status
/// design has no slot for.
class _StatusPill extends StatelessWidget {
  final AttendanceStatus current;
  final bool locked;
  final ValueChanged<AttendanceStatus> onChanged;

  const _StatusPill({required this.current, required this.locked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (locked) return AttendanceStatusPill(status: current.apiValue);
    final scheme = Theme.of(context).colorScheme;
    final pill = AttendanceStatusPill(
      status: current.apiValue,
      trailing: Icon(Icons.arrow_drop_down, size: 18, color: attendanceStatusStyle(current.apiValue, scheme).$3),
    );

    return PopupMenuButton<AttendanceStatus>(
      tooltip: 'Change status',
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final status in AttendanceStatus.values)
          PopupMenuItem(
            value: status,
            child: Row(
              children: [
                Icon(
                  attendanceStatusStyle(status.apiValue, scheme).$2,
                  size: 18,
                  color: attendanceStatusStyle(status.apiValue, scheme).$3,
                ),
                const SizedBox(width: 8),
                Text(status.label),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final String sectionId;
  final DateTime date;
  final TextEditingController subjectController;

  const _SubmitBar({required this.sectionId, required this.date, required this.subjectController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (provider.lastSubmitResult case final result?) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.10), borderRadius: AppRadius.card),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Attendance submitted and locked: ${result.savedCount} recorded'
                '${result.failed.isEmpty ? '' : ', ${result.failed.length} failed'}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.submitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(provider.submitError!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        FilledButton(
          onPressed: provider.isSubmitting
              ? null
              : () => provider.submit(
                  sectionId: sectionId,
                  date: _formatDate(date),
                  subject: subjectController.text.trim(),
                ),
          child: provider.isSubmitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit attendance'),
        ),
      ],
    );
  }
}
