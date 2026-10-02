import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/readable_color.dart';
import 'count_up_text.dart';

/// Small tinted count tile (icon, label, big value, optional coloured
/// caption such as a percentage) — the Present/Absent/Late style tiles on
/// the Students, Student Profile, Mark Attendance and attendance history
/// screens. Meant to sit 3–4 across in a `Row` of `Expanded`s.
class TintedStatTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final String? caption;
  final Color color;

  const TintedStatTile({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = context.readable(color);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      // Centered so tiles stretched to a common height (IntrinsicHeight rows)
      // keep their content in the middle.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, color: fg, size: 24), const SizedBox(height: 4)],
          Text(label, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CountUpText(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (caption != null && caption!.isNotEmpty)
            Text(caption!, maxLines: 1, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
