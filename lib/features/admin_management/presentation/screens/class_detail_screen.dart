import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/pill_tabs.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/student.dart';
import '../../data/models/teacher.dart';
import '../providers/academic_structure_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_provider.dart';
import '../widgets/class_badge.dart';
import 'classes_list_screen.dart' show confirmDeleteClass, showClassFormDialog;
import 'sections_list_screen.dart' show SectionsPanel, showSectionFormDialog;
import '../../../../shared/widgets/app_background.dart';

enum _Tab { overview, students, teachers, sections }

/// Admin: one class at a glance — reached by tapping a class in
/// [ClassesListScreen]. Built 2026-09-30 to a reference the user supplied
/// (`LMS UI/WhatsApp Image ... 3.47.05 PM.jpeg`): header card, Overview /
/// Students / Teachers / Sections tabs, and Manage Students / Edit Class
/// actions.
///
/// Everything shown is real: students are `StudentProvider`'s list matched
/// by class name (the same rule the Classes list counts with), teachers are
/// the union of this class's sections' assigned teachers
/// (`Section.teachers`) resolved to names via `TeacherProvider`. Not carried
/// over from the reference: its "Attendance Rate" stat (no per-class
/// attendance aggregate exists in the API) and its single "Class Teacher"
/// (the backend has no class-teacher field — teachers are assigned per
/// section — so this shows "Assigned Teachers" instead).
class ClassDetailScreen extends StatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  _Tab _tab = _Tab.overview;

  @override
  void initState() {
    super.initState();
    final academic = context.read<AcademicStructureProvider>();
    final students = context.read<StudentProvider>();
    final teachers = context.read<TeacherProvider>();
    Future.microtask(() {
      // Opened directly (deep link) the class list may not be loaded yet.
      if (academic.classes.every((c) => c.id != widget.classId)) academic.loadClasses();
      academic.loadSections(widget.classId);
      if (students.status != LoadStatus.success || students.classFilter != null) students.loadStudents();
      if (teachers.status != LoadStatus.success) teachers.loadTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicStructureProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final teacherProvider = context.watch<TeacherProvider>();

    final matches = academic.classes.where((c) => c.id == widget.classId);
    final academicClass = matches.isEmpty ? null : matches.first;

    if (academicClass == null) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const BrandAppBar(title: 'Class Details'),
          body: switch (academic.classesStatus) {
            LoadStatus.error => ErrorView(error: academic.classesError!, onRetry: academic.loadClasses),
            LoadStatus.success => const EmptyStateView(
              message: 'This class no longer exists',
              icon: Icons.school_outlined,
            ),
            _ => const LoadingView(message: 'Loading class...'),
          },
        ),
      );
    }

    final sectionsReady = academic.sectionsStatus == LoadStatus.success && academic.selectedClassId == widget.classId;
    final studentsReady = studentProvider.status == LoadStatus.success && studentProvider.classFilter == null;
    final students = studentsReady
        ? (studentProvider.students.where((s) => s.className == academicClass.name).toList()
            ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())))
        : null;
    final teacherIds = sectionsReady ? {for (final s in academic.sections) ...s.teacherIds} : null;
    final teachers = teacherIds != null && teacherProvider.status == LoadStatus.success
        ? teacherProvider.teachers.where((t) => teacherIds.contains(t.id)).toList()
        : null;
    final sectionCount = sectionsReady ? academic.sections.length : academicClass.sectionCount;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Class Details',
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Class options',
              onSelected: (_) async {
                final deleted = await confirmDeleteClass(context, academic, academicClass);
                if (deleted && context.mounted) context.pop();
              },
              itemBuilder: (context) => const [PopupMenuItem(value: 'delete', child: Text('Delete class'))],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.adminStudents),
                    icon: const Icon(Icons.group_outlined),
                    label: const Text('Manage Students'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => showClassFormDialog(context, academic, existing: academicClass),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Class'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeaderCard(academicClass: academicClass, studentCount: students?.length, sectionCount: sectionCount),
            const SizedBox(height: AppSpacing.lg),
            PillTabs<_Tab>(
              values: _Tab.values,
              labelOf: (tab) => switch (tab) {
                _Tab.overview => 'Overview',
                _Tab.students => 'Students',
                _Tab.teachers => 'Teachers',
                _Tab.sections => 'Sections',
              },
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...switch (_tab) {
              _Tab.overview => [
                _OverviewStats(students: students?.length, sections: sectionCount, teachers: teachers?.length),
                const SizedBox(height: AppSpacing.md),
                _TeachersCard(
                  teachers: teachers,
                  className: academicClass.name,
                  preview: true,
                  onViewAll: () => setState(() => _tab = _Tab.teachers),
                ),
                const SizedBox(height: AppSpacing.md),
                _StudentsPreviewCard(students: students, onViewAll: () => setState(() => _tab = _Tab.students)),
              ],
              _Tab.students => [_StudentsList(students: students)],
              _Tab.teachers => [_TeachersCard(teachers: teachers, className: academicClass.name, preview: false)],
              _Tab.sections => [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => showSectionFormDialog(context, academic, classId: widget.classId),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add Section'),
                  ),
                ),
                SectionsPanel(classId: widget.classId, embedded: true),
              ],
            },
          ],
        ),
      ),
    );
  }
}

String _plural(int n, String noun) => '$n ${n == 1 ? noun : '${noun}s'}';

class _HeaderCard extends StatelessWidget {
  final AcademicClass academicClass;
  final int? studentCount;
  final int? sectionCount;

  const _HeaderCard({required this.academicClass, required this.studentCount, required this.sectionCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final isActive = academicClass.status.toLowerCase() == 'active';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.10), const Color(0xFF2F80FF).withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          // Decorative, like the reference's cap-and-books illustration.
          Positioned(
            right: -10,
            bottom: -18,
            child: Icon(Icons.school_rounded, size: 110, color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClassBadge(name: academicClass.name, size: 72),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              academicClass.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          AppStatusChip(
                            label: isActive ? 'Active' : academicClass.status,
                            color: isActive ? AppColors.primary : theme.colorScheme.error,
                          ),
                        ],
                      ),
                      if (academicClass.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(academicClass.description, style: muted),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (studentCount != null)
                            _IconLabel(
                              icon: Icons.group_outlined,
                              label: _plural(studentCount!, 'Student'),
                              style: muted,
                            ),
                          if (sectionCount != null)
                            _IconLabel(
                              icon: Icons.layers_outlined,
                              label: _plural(sectionCount!, 'Section'),
                              style: muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? style;

  const _IconLabel({required this.icon, required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: style?.color),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}

/// Card with the reference's section header: soft round icon + title, and an
/// optional "View All →" on the right.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onViewAll;
  final Widget child;

  const _SectionCard({required this.icon, required this.title, this.onViewAll, required this.child});

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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('View All'), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16)],
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

class _OverviewStats extends StatelessWidget {
  final int? students;
  final int? sections;
  final int? teachers;

  const _OverviewStats({required this.students, required this.sections, required this.teachers});

  @override
  Widget build(BuildContext context) {
    String show(int? v) => v?.toString() ?? '–';
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      title: 'Class Overview',
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.groups_rounded,
              value: show(students),
              label: 'Total Students',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatTile(
              icon: Icons.layers_rounded,
              value: show(sections),
              label: 'Sections',
              color: const Color(0xFF2F80FF),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatTile(
              icon: Icons.person_rounded,
              value: show(teachers),
              label: teachers == 1 ? 'Assigned Teacher' : 'Assigned Teachers',
              color: const Color(0xFFF2600C),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          // Reserve two lines so all three tiles stay the same height when
          // one label ("Assigned Teachers") wraps.
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeachersCard extends StatelessWidget {
  final List<Teacher>? teachers;
  final String className;

  /// Overview shows the first few with "View All"; the Teachers tab shows all.
  final bool preview;
  final VoidCallback? onViewAll;

  const _TeachersCard({required this.teachers, required this.className, required this.preview, this.onViewAll});

  static const _previewCount = 2;

  @override
  Widget build(BuildContext context) {
    final list = teachers;
    final shown = list == null ? null : (preview ? list.take(_previewCount).toList() : list);
    return _SectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Assigned Teachers',
      onViewAll: preview && list != null && list.length > _previewCount ? onViewAll : null,
      child: switch (shown) {
        null => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        [] => const _Muted('No teachers assigned to this class\'s sections yet.'),
        _ => Column(
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const Divider(height: AppSpacing.lg),
              _PersonRow(
                name: shown[i].fullName,
                subtitle: [
                  if (shown[i].subjects.isNotEmpty)
                    shown[i].subjects.join(', ')
                  else if (shown[i].department.isNotEmpty)
                    shown[i].department,
                  className,
                ].join('  •  '),
              ),
            ],
          ],
        ),
      },
    );
  }
}

class _StudentsPreviewCard extends StatelessWidget {
  final List<Student>? students;
  final VoidCallback onViewAll;

  const _StudentsPreviewCard({required this.students, required this.onViewAll});

  static const _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    final list = students;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return _SectionCard(
      icon: Icons.groups_outlined,
      title: 'Students',
      onViewAll: list != null && list.isNotEmpty ? onViewAll : null,
      child: switch (list) {
        null => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        [] => const _Muted('No students in this class yet.'),
        _ => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in list.take(_previewCount))
              Expanded(
                child: InkWell(
                  onTap: () => context.push(AppRoutes.adminStudentProfile(s.id)),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: _AvatarTile(
                    avatar: _InitialsAvatar(name: s.fullName, radius: 24),
                    title: s.fullName,
                    subtitle: s.section.isEmpty ? '' : 'Section ${s.section}',
                    muted: muted,
                  ),
                ),
              ),
            if (list.length > _previewCount)
              Expanded(
                child: InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: _AvatarTile(
                    avatar: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.more_horiz_rounded, color: AppColors.primary),
                    ),
                    title: 'View More',
                    subtitle: '${list.length - _previewCount} more',
                    muted: muted,
                  ),
                ),
              )
            else
              // Keep tiles the same width when there are fewer than 5.
              for (var i = list.length; i <= _previewCount; i++) const Expanded(child: SizedBox()),
          ],
        ),
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final TextStyle? muted;

  const _AvatarTile({required this.avatar, required this.title, required this.subtitle, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        avatar,
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle.isNotEmpty) Text(subtitle, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _StudentsList extends StatelessWidget {
  final List<Student>? students;

  const _StudentsList({required this.students});

  @override
  Widget build(BuildContext context) {
    final list = students;
    if (list == null) return const LoadingView(message: 'Loading students...');
    if (list.isEmpty) {
      return const EmptyStateView(message: 'No students in this class yet', icon: Icons.groups_outlined);
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => context.push(AppRoutes.adminStudentProfile(list[i].id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: _PersonRow(
                  name: list[i].fullName,
                  subtitle: [
                    if (list[i].section.isNotEmpty) 'Section ${list[i].section}',
                    if (list[i].rollNumber.isNotEmpty) 'Roll ${list[i].rollNumber}',
                    if (list[i].admissionNumber.isNotEmpty) list[i].admissionNumber,
                  ].join('  •  '),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String subtitle;

  const _PersonRow({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _InitialsAvatar(name: name, radius: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const _InitialsAvatar({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        initialsFor(name),
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: radius * 0.6),
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  final String text;

  const _Muted(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}
