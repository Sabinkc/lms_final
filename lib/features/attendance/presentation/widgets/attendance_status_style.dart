import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/readable_color.dart';

/// The one attendance colour scheme every screen uses — Admin Students,
/// Student Profile, Mark Attendance, and the student/parent/teacher
/// history screens — so "Late" is the same purple everywhere.
abstract final class AttendanceColors {
  static const Color present = Color(0xFF16A34A);
  static const Color absent = Color(0xFFDC2626);
  static const Color late = Color(0xFF7C3AED);
  static const Color leave = Color(0xFF2F80FF);
  static const Color halfDay = Color(0xFFF59E0B);
}

/// Label, icon and colour for a backend status string (`present`, `absent`,
/// `late`, `leave`, `halfday`/`half_day`/`half-day`) or `notmarked`.
(String label, IconData icon, Color color) attendanceStatusStyle(String status, ColorScheme scheme) => switch (status
    .toLowerCase()
    .replaceAll(RegExp('[_ -]'), '')) {
  'present' => ('Present', Icons.check_circle, AttendanceColors.present),
  'absent' => ('Absent', Icons.cancel, AttendanceColors.absent),
  'late' => ('Late', Icons.schedule, AttendanceColors.late),
  'leave' => ('Leave', Icons.event_busy, AttendanceColors.leave),
  'halfday' => ('Half day', Icons.timelapse, AttendanceColors.halfDay),
  'notmarked' => ('Not marked', Icons.remove_circle_outline, scheme.outline),
  _ => (status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1), Icons.help_outline, scheme.outline),
};

/// Icon + label pill for one attendance status.
class AttendanceStatusPill extends StatelessWidget {
  final String status;

  /// Optional trailing widget inside the pill (e.g. a dropdown caret on
  /// Mark Attendance's tap-to-change pill).
  final Widget? trailing;

  const AttendanceStatusPill({super.key, required this.status, this.trailing});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = attendanceStatusStyle(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.readable(color)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: context.readable(color), fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (trailing != null) ...[const SizedBox(width: 2), trailing!],
        ],
      ),
    );
  }
}
