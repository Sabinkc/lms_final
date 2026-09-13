import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/data/models/teacher.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart';
import '../../../admin_management/presentation/providers/teacher_provider.dart';
import '../../data/models/timetable_day.dart';
import '../../data/models/timetable_period.dart';
import '../providers/admin_timetable_provider.dart';

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
      SnackBar(content: Text(succeeded ? 'Timetable saved' : provider.actionError?.message ?? 'Failed to save timetable')),
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
        content: Text('This will permanently delete the timetable for $_selectedClass $_selectedSection. This cannot be undone.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete timetable')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final academicProvider = context.watch<AcademicStructureProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final timetableProvider = context.watch<AdminTimetableProvider>();
    final canEdit = _selectedClass != null && _selectedSection != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
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
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [for (final c in academicProvider.classes) DropdownMenuItem(value: c.name, child: Text(c.name))],
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
                  items: [for (final s in academicProvider.sections) DropdownMenuItem(value: s.name, child: Text(s.name))],
                  onChanged: _selectedClass == null ? null : (value) => _selectClassSection(_selectedClass, value),
                ),
              ),
            ],
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
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.14),
          child: Icon(Icons.calendar_today_outlined, color: accent, size: 20),
        ),
        title: Text(day, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text('${periods.length} period(s)'),
        children: [
          for (final period in periods)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: period.subjectController,
                      decoration: const InputDecoration(labelText: 'Subject', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: period.startTimeController,
                      decoration: const InputDecoration(labelText: 'Start', hintText: '10:00 AM', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: period.endTimeController,
                      decoration: const InputDecoration(labelText: 'End', hintText: '11:00 AM', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: period.teacherId,
                      decoration: const InputDecoration(labelText: 'Teacher', isDense: true),
                      isExpanded: true,
                      items: [
                        for (final t in teacherOptions) DropdownMenuItem(value: t.id, child: Text(t.fullName, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (value) => period.teacherId = value,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remove period',
                    onPressed: () => onRemovePeriod(period),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddPeriod,
                icon: const Icon(Icons.add),
                label: const Text('Add period'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
