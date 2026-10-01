import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/initials.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../../core/theme/readable_color.dart';

/// On-screen look of a student's ID badge, built only from fields the
/// student record already has. The downloadable PDF from
/// `POST /idcards/student/:id` stays the official card; this is a preview
/// so the admin can confirm they picked the right student.
class IdBadgePreview extends StatelessWidget {
  final Student student;

  const IdBadgePreview({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergency = student.emergencyContactPhone?.isNotEmpty == true
        ? student.emergencyContactPhone!
        : (student.fatherMobile?.isNotEmpty == true
              ? student.fatherMobile!
              : (student.motherMobile?.isNotEmpty == true ? student.motherMobile! : student.phone));
    final fields = <(String, String)>[
      if (student.rollNumber.isNotEmpty) ('ROLL NO', '#${student.rollNumber}'),
      if (student.bloodGroup?.isNotEmpty == true) ('BLOOD GRP', student.bloodGroup!),
      if (student.dob.isNotEmpty) ('DATE OF BIRTH', formatDisplayDate(student.dob)),
      if (student.house?.isNotEmpty == true) ('HOUSE', student.house!),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/icon/app_icon.png', width: 34, height: 34, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'CLOUDSLMS',
                    style: TextStyle(color: Color(0xFFB9F6CA), fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'STUDENT PASS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    if (student.academicYear?.isNotEmpty == true)
                      Text(student.academicYear!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 84,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        initialsFor(student.fullName),
                        style: TextStyle(
                          color: context.readable(AppColors.primary),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (student.admissionNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ADM: ${student.admissionNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${student.className}${student.section.isNotEmpty ? ' · Section ${student.section}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [for (final (label, value) in fields) _Field(label: label, value: value)],
                      ),
                      if (emergency.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Field(label: 'EMERGENCY CONTACT', value: emergency, icon: Icons.phone_outlined),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    student.studentIdCode?.isNotEmpty == true ? 'ID: ${student.studentIdCode}' : 'Preview',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Text(
                  'Final card is the PDF',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _Field({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: context.readable(AppColors.primary)),
              const SizedBox(width: 4),
            ],
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
