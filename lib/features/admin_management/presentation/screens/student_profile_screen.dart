import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pill_tabs.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../attendance/presentation/widgets/attendance_status_style.dart';
import '../../../fees/presentation/widgets/fee_dashboard_widgets.dart' show FeeColors, formatRs;
import '../../data/models/student.dart';
import '../providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/student_profile_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import 'students_list_screen.dart' show confirmDeleteStudent, showStudentFormDialog;
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

enum _Tab { overview, academic, attendance, fees }

/// Admin: one student's full profile — reached by tapping a student in
/// [StudentsListScreen] or on Class Details. Built 2026-10-01 to a reference
/// the user supplied (`LMS UI/WhatsApp Image ... 3.49.17 PM.jpeg`): header
/// card with Edit, Overview / Academic / Attendance / Fees tabs.
///
/// Everything shown is real. Profile fields come from the student record
/// (most are optional and blank on real data, so rows only appear when
/// filled — nothing shows a placeholder value); attendance and fees come
/// from the per-student endpoints Admin is authorized for; "Section
/// Teacher" is whoever is assigned to the student's section (the backend
/// has no single class-teacher field). Not carried over from the reference:
/// Send Message (chat is class/section groups only — no 1:1), Call (no
/// dialer integration in this app), View Report (report cards are per exam,
/// and exam results by student are not available to Admin — the endpoint
/// returns "Access denied"), and the photo (initials instead — no photo is
/// stored on real records).
class StudentProfileScreen extends StatefulWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  _Tab _tab = _Tab.overview;

  @override
  void initState() {
    super.initState();
    final students = context.read<StudentProvider>();
    final teachers = context.read<TeacherProvider>();
    Future.microtask(() {
      if (students.students.every((s) => s.id != widget.studentId)) students.loadStudents();
      if (teachers.status != LoadStatus.success) teachers.loadTeachers();
    });
  }

  Future<void> _refresh() async {
    final students = context.read<StudentProvider>();
    final profile = context.read<StudentProfileProvider>();
    await Future.wait([
      students.loadStudents(className: students.classFilter, silent: true),
      context.read<TeacherProvider>().loadTeachers(silent: true),
      profile.loadAttendance(silent: true),
      profile.loadFees(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final profile = context.watch<StudentProfileProvider>();
    final student = studentProvider.students.where((s) => s.id == widget.studentId).firstOrNull;

    if (student == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const BrandAppBar(title: 'Student Profile'),
          body: PullToRefresh(
            onRefresh: _refresh,
            child: switch (studentProvider.status) {
              LoadStatus.error => ErrorView(error: studentProvider.error!, onRetry: studentProvider.loadStudents),
              LoadStatus.success when studentProvider.classFilter == null => const EmptyStateView(
                message: 'This student no longer exists',
                icon: Icons.person_off_outlined,
              ),
              LoadStatus.success => const _ReloadAll(),
              _ => const LoadingView(message: 'Loading student...'),
            },
          ),
        ),
      );
    }

    // Load (or reload after navigating from another student) once the
    // student record is known — section teachers are matched by its names.
    if (profile.studentId != student.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && profile.studentId != student.id) profile.load(student);
      });
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Student Profile',
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Student options',
              onSelected: (_) async {
                final deleted = await confirmDeleteStudent(context, studentProvider, student);
                if (deleted && context.mounted) context.pop();
              },
              itemBuilder: (context) => const [PopupMenuItem(value: 'delete', child: Text('Delete student'))],
            ),
          ],
        ),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _ProfileHeader(
                student: student,
                onEdit: () => showStudentFormDialog(context, studentProvider, existing: student),
              ),
              const SizedBox(height: AppSpacing.lg),
              PillTabs<_Tab>(
                values: _Tab.values,
                labelOf: (tab) => switch (tab) {
                  _Tab.overview => 'Overview',
                  _Tab.academic => 'Academic',
                  _Tab.attendance => 'Attendance',
                  _Tab.fees => 'Fees',
                },
                iconOf: (tab) => switch (tab) {
                  _Tab.overview => Icons.description_outlined,
                  _Tab.academic => Icons.school_outlined,
                  _Tab.attendance => Icons.event_available_outlined,
                  _Tab.fees => Icons.payments_outlined,
                },
                selected: _tab,
                onSelected: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...switch (_tab) {
                _Tab.overview => [
                  _PersonalInfoCard(student: student),
                  const SizedBox(height: AppSpacing.md),
                  _GuardianCard(student: student),
                  const SizedBox(height: AppSpacing.md),
                  _ClassInfoCard(student: student, teacherNames: _sectionTeacherNames(context, profile)),
                ],
                _Tab.academic => [
                  _ClassInfoCard(student: student, teacherNames: _sectionTeacherNames(context, profile)),
                  const SizedBox(height: AppSpacing.md),
                  _AdditionalDetailsCard(student: student),
                ],
                _Tab.attendance => [_AttendanceTab(profile: profile)],
                _Tab.fees => [_FeesTab(profile: profile)],
              },
            ],
          ),
        ),
      ),
    );
  }

  /// `null` while still resolving.
  List<String>? _sectionTeacherNames(BuildContext context, StudentProfileProvider profile) {
    final ids = profile.sectionTeacherIds;
    final teachers = context.watch<TeacherProvider>();
    if (ids == null || teachers.status != LoadStatus.success) return null;
    return [
      for (final t in teachers.teachers)
        if (ids.contains(t.id)) t.fullName,
    ];
  }
}

/// The Students screen left a class filter on the shared list and this
/// student isn't in it — reload the full list once.
class _ReloadAll extends StatefulWidget {
  const _ReloadAll();

  @override
  State<_ReloadAll> createState() => _ReloadAllState();
}

class _ReloadAllState extends State<_ReloadAll> {
  @override
  void initState() {
    super.initState();
    final students = context.read<StudentProvider>();
    Future.microtask(() => students.loadStudents());
  }

  @override
  Widget build(BuildContext context) => const LoadingView(message: 'Loading student...');
}

String? _age(String dob) {
  final date = DateTime.tryParse(dob);
  if (date == null) return null;
  final now = DateTime.now();
  var age = now.year - date.year;
  if (now.month < date.month || (now.month == date.month && now.day < date.day)) age--;
  return age >= 0 ? '$age' : null;
}

String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _ProfileHeader extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.student, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final isActive = student.status.toLowerCase() == 'active';
    final idLabel = student.studentIdCode ?? (student.admissionNumber.isEmpty ? null : student.admissionNumber);
    final joined = student.admissionDate ?? student.createdAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.10), const Color(0xFF2F80FF).withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initialsFor(student.fullName),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF22C55E) : theme.colorScheme.outline,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (student.className.isNotEmpty) student.className,
                        if (student.section.isNotEmpty) 'Section ${student.section}',
                      ].join('  •  '),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppStatusChip(
                      label: isActive ? 'Active' : _titleCase(student.status),
                      color: isActive ? AppColors.primary : theme.colorScheme.error,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          if (idLabel != null || joined != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                if (idLabel != null) _IconText(icon: Icons.badge_outlined, text: 'Student ID: $idLabel', style: muted),
                if (joined != null)
                  _IconText(
                    icon: Icons.calendar_month_outlined,
                    text: 'Joined: ${formatDisplayDate(joined)}',
                    style: muted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;

  const _IconText({required this.icon, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: style?.color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}

/// Card with the reference's section header: green icon + bold title.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: context.readable(AppColors.primary)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

typedef _Row = (IconData icon, String label, String value);

/// Label/value rows, only for the values that are actually filled in.
class _Rows extends StatelessWidget {
  final List<_Row> rows;
  final String emptyMessage;

  const _Rows({required this.rows, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (rows.isEmpty) return Text(emptyMessage, style: muted);
    return Column(
      children: [
        for (final (icon, label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(width: 118, child: Text(label, style: muted)),
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final Student student;

  const _PersonalInfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final age = _age(student.dob);
    return _InfoCard(
      icon: Icons.person_rounded,
      title: 'Personal Information',
      child: _Rows(
        emptyMessage: 'No personal details recorded.',
        rows: [
          (Icons.badge_outlined, 'Full Name', student.fullName),
          if (student.dob.isNotEmpty)
            (
              Icons.cake_outlined,
              'Date of Birth',
              '${formatDisplayDate(student.dob)}${age == null ? '' : ' (Age $age)'}',
            ),
          if (student.gender != null) (Icons.wc_outlined, 'Gender', _titleCase(student.gender!)),
          if (student.phone.isNotEmpty) (Icons.phone_outlined, 'Phone', student.phone),
          if (student.email.isNotEmpty) (Icons.mail_outline, 'Email', student.email),
          if (student.address.isNotEmpty) (Icons.location_on_outlined, 'Address', student.address),
          if (student.bloodGroup != null) (Icons.water_drop_outlined, 'Blood Group', student.bloodGroup!),
        ],
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final Student student;

  const _GuardianCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    String withSub(String name, String? sub) => sub == null ? name : '$name ($sub)';
    return _InfoCard(
      icon: Icons.family_restroom_rounded,
      title: 'Guardian & Family',
      child: _Rows(
        emptyMessage: 'No guardian or parent linked yet.',
        rows: [
          if (s.parentName != null) (Icons.supervisor_account_outlined, 'Parent Account', s.parentName!),
          if (s.parentEmail != null) (Icons.mail_outline, 'Parent Email', s.parentEmail!),
          if (s.guardianName != null)
            (Icons.person_outline, 'Guardian', withSub(s.guardianName!, s.guardianRelationship)),
          if (s.guardianEmail != null) (Icons.mail_outline, 'Guardian Email', s.guardianEmail!),
          if (s.fatherName != null) (Icons.man_outlined, 'Father', s.fatherName!),
          if (s.fatherMobile != null) (Icons.phone_outlined, 'Father\'s Phone', s.fatherMobile!),
          if (s.motherName != null) (Icons.woman_outlined, 'Mother', s.motherName!),
          if (s.motherMobile != null) (Icons.phone_outlined, 'Mother\'s Phone', s.motherMobile!),
          if (s.emergencyContactName != null)
            (
              Icons.emergency_outlined,
              'Emergency Contact',
              withSub(s.emergencyContactName!, s.emergencyContactRelationship),
            ),
          if (s.emergencyContactPhone != null)
            (Icons.phone_in_talk_outlined, 'Emergency Phone', s.emergencyContactPhone!),
        ],
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  final Student student;

  /// `null` while loading.
  final List<String>? teacherNames;

  const _ClassInfoCard({required this.student, required this.teacherNames});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teachers = teacherNames;
    return _InfoCard(
      icon: Icons.school_rounded,
      title: 'Class Information',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _ClassCell(label: 'Class', value: student.className, color: const Color(0xFF2F80FF)),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _ClassCell(label: 'Section', value: student.section, color: AppColors.primary),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Section Teacher', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      switch (teachers) {
                        null => '…',
                        [] => 'Not assigned',
                        _ => teachers.join(', '),
                      },
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: teachers?.isEmpty ?? false ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _ClassCell(label: 'Roll No.', value: student.rollNumber, color: const Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ClassCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xl4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              // Class name "Class 10" -> "10" in the pill, as in the reference.
              value.isEmpty ? '–' : (RegExp(r'\d+').firstMatch(value)?.group(0) ?? value),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: context.readable(color)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdditionalDetailsCard extends StatelessWidget {
  final Student student;

  const _AdditionalDetailsCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return _InfoCard(
      icon: Icons.article_rounded,
      title: 'Additional Details',
      child: _Rows(
        emptyMessage: 'No additional details recorded.',
        rows: [
          if (s.admissionNumber.isNotEmpty) (Icons.confirmation_number_outlined, 'Admission No.', s.admissionNumber),
          if (s.admissionDate != null) (Icons.event_outlined, 'Admission Date', formatDisplayDate(s.admissionDate!)),
          (Icons.circle_outlined, 'Status', _titleCase(s.status)),
          if (s.academicYear != null) (Icons.date_range_outlined, 'Academic Year', s.academicYear!),
          if (s.house != null) (Icons.home_outlined, 'House', s.house!),
          if (s.secondSubject != null) (Icons.menu_book_outlined, 'Second Subject', s.secondSubject!),
          if (s.previousSchool != null) (Icons.account_balance_outlined, 'Previous School', s.previousSchool!),
          if (s.previousGrade != null) (Icons.grade_outlined, 'Previous Grade', s.previousGrade!),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final StudentProfileProvider profile;

  const _AttendanceTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final history = profile.attendance;
    return switch (profile.attendanceStatus) {
      LoadStatus.error => ErrorView(error: profile.attendanceError!, onRetry: profile.loadAttendance),
      LoadStatus.success when history != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TintedStatTile(value: '${history.summary.percentage}%', label: 'Rate', color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(
                  value: '${history.summary.present}',
                  label: 'Present',
                  color: AttendanceColors.present,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(
                  value: '${history.summary.absent}',
                  label: 'Absent',
                  color: AttendanceColors.absent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(value: '${history.summary.late}', label: 'Late', color: AttendanceColors.late),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (history.records.isEmpty)
            const EmptyStateView(message: 'No attendance recorded yet', icon: Icons.event_busy_outlined)
          else
            _InfoCard(
              icon: Icons.event_note_rounded,
              title: 'Recent Attendance',
              child: Column(
                children: [
                  for (var i = 0; i < history.records.length && i < 30; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDisplayDate(history.records[i].date),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (history.records[i].subject.isNotEmpty)
                                  Text(history.records[i].subject, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          AttendanceStatusPill(status: history.records[i].status),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      _ => const LoadingView(message: 'Loading attendance...'),
    };
  }
}

class _FeesTab extends StatelessWidget {
  final StudentProfileProvider profile;

  const _FeesTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final summary = profile.feesSummary;
    final theme = Theme.of(context);
    return switch (profile.feesStatus) {
      LoadStatus.error => ErrorView(error: profile.feesError!, onRetry: profile.loadFees),
      LoadStatus.success when summary != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TintedStatTile(value: formatRs(summary.totalDue), label: 'Total Due', color: FeeColors.pending),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(value: '${summary.paid}', label: 'Paid', color: FeeColors.paid),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(value: '${summary.partial}', label: 'Partial', color: FeeColors.partial),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TintedStatTile(value: '${summary.pending}', label: 'Pending', color: FeeColors.pending),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (profile.fees.isEmpty)
            const EmptyStateView(message: 'No fees assigned to this student', icon: Icons.receipt_long_outlined)
          else
            _InfoCard(
              icon: Icons.receipt_long_rounded,
              title: 'Fees',
              child: Column(
                children: [
                  for (var i = 0; i < profile.fees.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fees[i].title,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  [
                                    if (profile.fees[i].dueDate.isNotEmpty)
                                      'Due ${formatDisplayDate(profile.fees[i].dueDate)}',
                                    if (profile.fees[i].remainingAmount > 0)
                                      '${formatRs(profile.fees[i].remainingAmount)} left',
                                  ].join('  •  '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatRs(profile.fees[i].totalAmount),
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              AppStatusChip(
                                label: _titleCase(profile.fees[i].status),
                                color: switch (profile.fees[i].status) {
                                  'paid' => FeeColors.paid,
                                  'partial' => FeeColors.partial,
                                  _ => FeeColors.pending,
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      _ => const LoadingView(message: 'Loading fees...'),
    };
  }
}
