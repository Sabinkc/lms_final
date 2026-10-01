import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/data/models/teacher.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart';
import '../../../admin_management/presentation/providers/teacher_provider.dart';
import '../../data/models/timetable_day.dart';
import '../../data/models/timetable_period.dart';
import '../providers/admin_timetable_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

class _PeriodDraft {
  int periodNumber;
  String? teacherId;
  final subjectController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final roomController = TextEditingController();

  _PeriodDraft({required this.periodNumber, this.teacherId});

  factory _PeriodDraft.fromPeriod(TimetablePeriod period) {
    final draft = _PeriodDraft(periodNumber: period.periodNumber, teacherId: period.teacherId);
    draft.subjectController.text = period.subject;
    draft.startTimeController.text = period.startTime;
    draft.endTimeController.text = period.endTime;
    draft.roomController.text = period.room ?? '';
    return draft;
  }

  TimetablePeriodInput toInput() => TimetablePeriodInput(
    periodNumber: periodNumber,
    subject: subjectController.text.trim(),
    teacherId: teacherId,
    startTime: startTimeController.text.trim(),
    endTime: endTimeController.text.trim(),
    room: roomController.text.trim(),
  );
}

/// Admin: Manage Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F1) — pick a Class + Section (same
/// `AcademicStructureProvider` picker `exam_form_dialog.dart` uses), then
/// edit each weekday's periods in a grid. Saving is an upsert
/// (`AdminTimetableProvider.saveTimetable`), so there's no separate
/// create/edit mode to track.
class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> {
  String? _selectedClass;
  String? _selectedSection;
  final Map<String, List<_PeriodDraft>> _draft = {for (final day in timetableWeekdays) day: []};

  @override
  void initState() {
    super.initState();
    final academicProvider = context.read<AcademicStructureProvider>();
    final teacherProvider = context.read<TeacherProvider>();
    Future.microtask(() {
      if (academicProvider.classesStatus != LoadStatus.success) academicProvider.loadClasses();
      if (teacherProvider.teachers.isEmpty) teacherProvider.loadTeachers();
    });
  }

  @override
  void dispose() {
    for (final periods in _draft.values) {
      for (final p in periods) {
        p.subjectController.dispose();
        p.startTimeController.dispose();
        p.endTimeController.dispose();
        p.roomController.dispose();
      }
    }
    super.dispose();
  }

  void _resetDraft() {
    for (final periods in _draft.values) {
      periods.clear();
    }
  }

  Future<void> _selectClassSection(String? className, String? section) async {
    setState(() {
      _selectedClass = className;
      _selectedSection = section;
      _resetDraft();
    });
    if (className == null || section == null) return;

    final provider = context.read<AdminTimetableProvider>();
    await provider.loadTimetable(className, section);
    if (!mounted) return;

    final current = provider.current;
    setState(() {
      _resetDraft();
      if (current != null) {
        for (final day in current.schedule) {
          _draft[day.day] = [for (final p in day.periods) _PeriodDraft.fromPeriod(p)];
        }
      }
    });
  }

  Future<void> _save() async {
    final provider = context.read<AdminTimetableProvider>();
    final schedule = [
      for (final day in timetableWeekdays)
        if (_draft[day]!.isNotEmpty) TimetableDayInput(day: day, periods: [for (final p in _draft[day]!) p.toInput()]),
    ];

    final succeeded = await provider.saveTimetable(
      className: _selectedClass!,
      section: _selectedSection!,
      schedule: schedule,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(succeeded ? 'Timetable saved' : provider.actionError?.message ?? 'Failed to save timetable'),
      ),
    );
  }

  Future<void> _delete() async {
    final provider = context.read<AdminTimetableProvider>();
    final current = provider.current;
    if (current == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete timetable?'),
        content: Text(
          'This will permanently delete the timetable for $_selectedClass $_selectedSection. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final succeeded = await provider.deleteTimetable(current.id);
    if (!mounted) return;
    if (succeeded) {
      setState(_resetDraft);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete timetable')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final academicProvider = context.watch<AcademicStructureProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final timetableProvider = context.watch<AdminTimetableProvider>();
    final canEdit = _selectedClass != null && _selectedSection != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Timetable',
          actions: [
            if (canEdit && timetableProvider.current != null)
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete timetable', onPressed: _delete),
          ],
        ),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: timetableProvider.isSaving ? null : _save,
                icon: timetableProvider.isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_view_week_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Master Class Schedule',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (canEdit && timetableProvider.status == LoadStatus.success)
                          AppStatusPill(
                            label: timetableProvider.current != null ? 'Saved timetable' : 'New timetable',
                            icon: timetableProvider.current != null ? Icons.cloud_done_outlined : Icons.edit_note,
                            color: timetableProvider.current != null
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEA580C),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(labelText: 'Class'),
                            items: [
                              for (final c in academicProvider.classes)
                                DropdownMenuItem(value: c.name, child: Text(c.name)),
                            ],
                            onChanged: (value) async {
                              final matching = academicProvider.classes.where((c) => c.name == value);
                              if (matching.isNotEmpty) await academicProvider.loadSections(matching.first.id);
                              if (!mounted) return;
                              await _selectClassSection(value, null);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSection,
                            decoration: const InputDecoration(labelText: 'Section'),
                            items: [
                              for (final s in academicProvider.sections)
                                DropdownMenuItem(value: s.name, child: Text(s.name)),
                            ],
                            onChanged: _selectedClass == null
                                ? null
                                : (value) => _selectClassSection(_selectedClass, value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!canEdit)
              const EmptyStateView(message: 'Pick a class and section to view or edit its timetable')
            else
              switch (timetableProvider.status) {
                LoadStatus.loading => const LoadingView(message: 'Loading timetable...'),
                LoadStatus.error => ErrorView(
                  error: timetableProvider.error!,
                  onRetry: () => _selectClassSection(_selectedClass, _selectedSection),
                ),
                LoadStatus.initial || LoadStatus.success => Column(
                  children: [
                    for (final day in timetableWeekdays)
                      _DaySection(
                        day: day,
                        periods: _draft[day]!,
                        teacherOptions: teacherProvider.teachers,
                        onAddPeriod: () => setState(() {
                          final nextNumber = _draft[day]!.length + 1;
                          _draft[day]!.add(_PeriodDraft(periodNumber: nextNumber));
                        }),
                        onRemovePeriod: (period) => setState(() => _draft[day]!.remove(period)),
                      ),
                  ],
                ),
              },
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<_PeriodDraft> periods;
  final List<Teacher> teacherOptions;
  final VoidCallback onAddPeriod;
  final ValueChanged<_PeriodDraft> onRemovePeriod;

  const _DaySection({
    required this.day,
    required this.periods,
    required this.teacherOptions,
    required this.onAddPeriod,
    required this.onRemovePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = {
      for (final p in periods)
        if (p.subjectController.text.trim().isNotEmpty) p.subjectController.text.trim(),
    };
    final first = periods.isEmpty ? '' : periods.first.startTimeController.text.trim();
    final last = periods.isEmpty ? '' : periods.last.endTimeController.text.trim();
    final count = '${periods.length} period${periods.length == 1 ? '' : 's'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: periods.isEmpty ? 0.06 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              day[0],
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          title: Text(day, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periods.isEmpty
                    ? 'No periods yet'
                    : (first.isNotEmpty && last.isNotEmpty ? '$count ($first – $last)' : count),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final subject in subjects.take(5)) AppStatusPill(label: subject, color: AppColors.info),
                  ],
                ),
              ],
            ],
          ),
          children: [
            for (final period in periods) ...[
              _PeriodEditor(period: period, teacherOptions: teacherOptions, onRemove: () => onRemovePeriod(period)),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: onAddPeriod,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add period'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodEditor extends StatelessWidget {
  final _PeriodDraft period;
  final List<Teacher> teacherOptions;
  final VoidCallback onRemove;

  const _PeriodEditor({required this.period, required this.teacherOptions, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surface;
    InputDecoration field(String label, {String? hint, IconData? icon}) => InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: fill,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  'P${period.periodNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                tooltip: 'Remove period',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: period.startTimeController,
                  decoration: field('Start', hint: '10:00 AM', icon: Icons.schedule),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: period.endTimeController,
                  decoration: field('End', hint: '11:00 AM', icon: Icons.schedule),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: period.subjectController,
            decoration: field('Subject', icon: Icons.menu_book_outlined),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: period.teacherId,
                  decoration: field('Teacher', icon: Icons.person_outline),
                  isExpanded: true,
                  items: [
                    for (final t in teacherOptions)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.fullName, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => period.teacherId = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: period.roomController,
                  decoration: field('Room'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
