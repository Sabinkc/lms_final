import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/download_helper.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../attendance/presentation/widgets/attendance_status_style.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/student.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/student_day_attendance_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/class_badge.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md "Manage Students — List / Add-Edit / Detail". Tapping a
/// student opens `StudentProfileScreen`. See [_StudentsBody] for the
/// 2026-10-01 attendance-style restyle. Parent linking (`parentId`) is deferred to Phase B4 — there's no Parent
/// list yet to pick from, so the create/edit form doesn't expose that field.
class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  /// `null` = all statuses.
  DayStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudentProvider>();
    final attendance = context.read<StudentDayAttendanceProvider>();
    Future.microtask(() {
      provider.loadStudents();
      provider.loadClassOptions();
      attendance.load();
    });
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(StudentDayAttendanceProvider attendance) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: attendance.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) attendance.load(date: picked);
  }

  Future<void> _refresh() async {
    final provider = context.read<StudentProvider>();
    await Future.wait([
      provider.loadStudents(className: provider.classFilter, silent: true),
      context.read<StudentDayAttendanceProvider>().load(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final attendance = context.watch<StudentDayAttendanceProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Students',
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Bulk import',
              onPressed: () => _showBulkImportDialog(context, provider),
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export students',
              onPressed: () => _downloadExport(context, provider),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showStudentFormDialog(context, provider),
          tooltip: 'Add Student',
          child: const Icon(Icons.add),
        ),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: Column(
            children: [
              _ClassFilterBar(
                classOptions: provider.classOptions,
                selected: provider.classFilter,
                onChanged: (className) => provider.loadStudents(className: className),
              ),
              Expanded(
                child: switch (provider.status) {
                  LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading students...'),
                  LoadStatus.error => ErrorView(
                    error: provider.error!,
                    onRetry: () => provider.loadStudents(className: provider.classFilter),
                  ),
                  LoadStatus.success =>
                    provider.students.isEmpty
                        ? EmptyStateView(
                            message: 'No students added yet',
                            icon: Icons.school_outlined,
                            actionLabel: 'Add Student',
                            onAction: () => showStudentFormDialog(context, provider),
                          )
                        : _StudentsBody(
                            searchController: _searchController,
                            allStudents: provider.students,
                            students: provider.students.where((s) {
                              if (_statusFilter != null && attendance.statusFor(s) != _statusFilter) return false;
                              return _query.isEmpty ||
                                  s.fullName.toLowerCase().contains(_query) ||
                                  s.admissionNumber.toLowerCase().contains(_query);
                            }).toList(),
                            selectedClass: provider.classOptions
                                .where((c) => c.name == provider.classFilter)
                                .firstOrNull,
                            attendance: attendance,
                            statusFilter: _statusFilter,
                            onStatusFilter: (status) => setState(() => _statusFilter = status),
                            onPickDate: () => _pickDate(attendance),
                            onEdit: (student) => showStudentFormDialog(context, provider, existing: student),
                            onDelete: (student) => confirmDeleteStudent(context, provider, student),
                          ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassFilterBar extends StatelessWidget {
  final List<AcademicClass> classOptions;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _ClassFilterBar({required this.classOptions, required this.selected, required this.onChanged});

  static const _all = 'All';

  @override
  Widget build(BuildContext context) {
    if (classOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppFilterChipBar<String>(
        options: [_all, for (final c in classOptions) c.name],
        selected: selected ?? _all,
        labelBuilder: (option) => option,
        onSelected: (option) => onChanged(option == _all ? null : option),
      ),
    );
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// `Thu, 16 Apr 2025`, as in the reference's date picker.
String _dayLabel(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// Restyled 2026-10-01 to a reference the user supplied (`LMS UI/WhatsApp
/// Image ... 3.49.18 PM.jpeg`): class header with View Class, a date picker,
/// Total / Present / Absent / Late tiles for that day, search + status
/// filter, and each student with that day's attendance pill. Photos are
/// initials (none are stored); students with no attendance taken that day
/// show "Not marked" rather than being counted as present or absent.
class _StudentsBody extends StatelessWidget {
  final TextEditingController searchController;
  final List<Student> allStudents;
  final List<Student> students;
  final AcademicClass? selectedClass;
  final StudentDayAttendanceProvider attendance;
  final DayStatus? statusFilter;
  final ValueChanged<DayStatus?> onStatusFilter;
  final VoidCallback onPickDate;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student> onDelete;

  const _StudentsBody({
    required this.searchController,
    required this.allStudents,
    required this.students,
    required this.selectedClass,
    required this.attendance,
    required this.statusFilter,
    required this.onStatusFilter,
    required this.onPickDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loaded = attendance.status == LoadStatus.success;
    int count(DayStatus s) => allStudents.where((st) => attendance.statusFor(st) == s).length;
    final total = allStudents.length;
    String pct(int n) => total == 0 ? '(0%)' : '(${(n / total * 100).toStringAsFixed(1)}%)';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        _HeaderCard(selectedClass: selectedClass, studentCount: total),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Attendance',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(_dayLabel(attendance.date)), const Icon(Icons.expand_more, size: 18)],
              ),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.groups_rounded,
                label: 'Total',
                value: '$total',
                caption: 'students',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            for (final (status, label) in const [
              (DayStatus.present, 'Present'),
              (DayStatus.absent, 'Absent'),
              (DayStatus.late, 'Late'),
            ]) ...[
              Expanded(
                child: TintedStatTile(
                  icon: attendanceStatusStyle(status.name, scheme).$2,
                  label: label,
                  value: loaded ? '${count(status)}' : '–',
                  caption: loaded ? pct(count(status)) : '',
                  color: attendanceStatusStyle(status.name, scheme).$3,
                ),
              ),
              if (status != DayStatus.late) const SizedBox(width: 8),
            ],
          ],
        ),
        if (attendance.status == LoadStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Couldn\'t load attendance: ${attendance.error?.message ?? 'unknown error'}',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
                TextButton(onPressed: attendance.load, child: const Text('Retry')),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search student...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterButton(selected: statusFilter, onSelected: onStatusFilter),
                  ],
                ),
              ),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyStateView(message: 'No students match your search'),
                )
              else
                for (var i = 0; i < students.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  _StudentRow(
                    student: students[i],
                    status: attendance.statusFor(students[i]),
                    onEdit: () => onEdit(students[i]),
                    onDelete: () => onDelete(students[i]),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final AcademicClass? selectedClass;
  final int studentCount;

  const _HeaderCard({required this.selectedClass, required this.studentCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cls = selectedClass;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), const Color(0xFF2F80FF).withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          if (cls != null)
            ClassBadge(name: cls.name, size: 56)
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl2)),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls?.name ?? 'All Students',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  [
                    if (cls != null && cls.description.isNotEmpty) cls.description,
                    '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                    if (cls == null) 'all classes',
                  ].join('  •  '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (cls != null)
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.adminClassDetail(cls.id)),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('View Class'), Icon(Icons.chevron_right, size: 18)],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  final DayStatus? selected;
  final ValueChanged<DayStatus?> onSelected;

  const _StatusFilterButton({required this.selected, required this.onSelected});

  static String _label(DayStatus? s) => switch (s) {
    null => 'All',
    DayStatus.present => 'Present',
    DayStatus.absent => 'Absent',
    DayStatus.late => 'Late',
    DayStatus.leave => 'Leave',
    DayStatus.notMarked => 'Not marked',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<DayStatus?>(
      tooltip: 'Filter by attendance',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final s in <DayStatus?>[null, ...DayStatus.values])
          CheckedPopupMenuItem(value: s, checked: s == selected, child: Text(_label(s))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppRadius.xl4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 18, color: context.readable(AppColors.primary)),
            const SizedBox(width: 4),
            Text(
              _label(selected),
              style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final Student student;
  final DayStatus? status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentRow({required this.student, required this.status, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: () => context.push(AppRoutes.adminStudentProfile(student.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initialsFor(student.fullName),
                style: TextStyle(color: context.readable(AppColors.primary), fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [
                      if (student.className.isNotEmpty) student.className,
                      if (student.section.isNotEmpty) 'Section ${student.section}',
                    ].join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (status != null) AttendanceStatusPill(status: status!.name),
            PopupMenuButton<String>(
              tooltip: 'Student actions',
              icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              onSelected: (value) => switch (value) {
                'view' => context.push(AppRoutes.adminStudentProfile(student.id)),
                'edit' => onEdit(),
                _ => onDelete(),
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'view', child: Text('View profile')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showStudentFormDialog(BuildContext context, StudentProvider provider, {Student? existing}) async {
  final fullNameController = TextEditingController(text: existing?.fullName);
  final emailController = TextEditingController(text: existing?.email);
  final admissionController = TextEditingController(text: existing?.admissionNumber);
  final rollController = TextEditingController(text: existing?.rollNumber);
  final phoneController = TextEditingController(text: existing?.phone);
  final formKey = GlobalKey<FormState>();

  String? selectedClass = existing?.className;
  String? selectedSection = existing?.section;
  if (selectedClass != null) {
    final matching = provider.classOptions.where((c) => c.name == selectedClass);
    if (matching.isNotEmpty) await provider.loadSectionOptions(matching.first.id);
  }
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  enabled: existing == null,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Full name is required' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: existing == null,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [for (final c in provider.classOptions) DropdownMenuItem(value: c.name, child: Text(c.name))],
                  validator: (value) => value == null ? 'Class is required' : null,
                  onChanged: (value) async {
                    selectedClass = value;
                    selectedSection = null;
                    final matching = provider.classOptions.where((c) => c.name == value);
                    if (matching.isNotEmpty) await provider.loadSectionOptions(matching.first.id);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSection,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: [
                    for (final s in provider.sectionOptions) DropdownMenuItem(value: s.name, child: Text(s.name)),
                  ],
                  validator: (value) => value == null ? 'Section is required' : null,
                  onChanged: (value) {
                    selectedSection = value;
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: admissionController,
                  decoration: const InputDecoration(labelText: 'Admission number (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rollController,
                  decoration: const InputDecoration(labelText: 'Roll number (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                if (provider.actionError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.actionError!.message,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = existing == null
                        ? await provider.createStudent(
                            className: selectedClass!,
                            section: selectedSection!,
                            fullName: fullNameController.text.trim(),
                            email: emailController.text.trim(),
                            admissionNumber: admissionController.text.trim(),
                            rollNumber: rollController.text.trim(),
                            phone: phoneController.text.trim(),
                          )
                        : await provider.updateStudent(
                            id: existing.id,
                            className: selectedClass,
                            section: selectedSection,
                            admissionNumber: admissionController.text.trim(),
                            rollNumber: rollController.text.trim(),
                            phone: phoneController.text.trim(),
                          );
                    if (succeeded && dialogContext.mounted) Navigator.of(dialogContext).pop();
                    setDialogState(() {});
                  },
            child: provider.isSaving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// Returns whether the student was actually deleted.
Future<bool> confirmDeleteStudent(BuildContext context, StudentProvider provider, Student student) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete student?'),
      content: Text(
        'This will permanently delete "${student.fullName}" and their login account. This cannot be undone.',
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

  if (confirmed != true || !context.mounted) return false;

  final succeeded = await runWithProgress(context, () => provider.deleteStudent(student.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete student')));
  }
  return succeeded;
}

Future<void> _showBulkImportDialog(BuildContext context, StudentProvider provider) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Bulk import students'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload an Excel (.xlsx/.xls) or CSV file with Full Name, Email, Class, Section columns.'),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Download template'),
                onPressed: () async {
                  final bytes = await runWithProgress(
                    dialogContext,
                    provider.downloadImportTemplate,
                    message: 'Downloading template…',
                  );
                  if (bytes != null && dialogContext.mounted) {
                    await saveBytesOrNotify(dialogContext, bytes, 'student_import_template.xlsx');
                  }
                },
              ),
              const SizedBox(height: 12),
              if (provider.isImporting) const Center(child: CircularProgressIndicator()),
              if (provider.importError != null)
                Text(provider.importError!.message, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
              if (provider.lastImportResult case final result?) ...[
                Text('${result.createdCount} of ${result.totalRows} rows imported.'),
                for (final f in result.failed) Text('Row ${f.row}: ${f.reason}', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Choose file'),
            onPressed: provider.isImporting
                ? null
                : () async {
                    final file = await FilePicker.pickFile(
                      type: FileType.custom,
                      allowedExtensions: ['xlsx', 'xls', 'csv'],
                    );
                    if (file == null) return;
                    final bytes = await file.readAsBytes();
                    if (!dialogContext.mounted) return;
                    await runWithProgress(
                      dialogContext,
                      () => provider.bulkImport(bytes, file.name),
                      message: 'Importing students…',
                    );
                    setDialogState(() {});
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _downloadExport(BuildContext context, StudentProvider provider) async {
  final bytes = await provider.exportStudents();
  if (bytes != null) {
    if (context.mounted) await saveBytesOrNotify(context, bytes, 'student_roster.xlsx');
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.downloadError?.message ?? 'Failed to export students')));
  }
}
