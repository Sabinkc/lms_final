import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/readable_color.dart';

/// A small colored pill for a status label (paid/pending/present/absent/
/// new/...). Promoted from the private `_StatusChip` that used to live only
/// in `fees/presentation/screens/payment_review_screen.dart`, so every
/// feature that shows a status (Fees, Attendance, Notices' "New" badge,
/// Payroll) shares one look instead of reimplementing the same `Chip`
/// styling per screen.
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AppStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final fg = context.readable(color);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// A compact rounded status badge with an optional leading icon — the
/// "✓ Published" / "⏱ Upcoming" pill from the Stitch card headers. Lighter
/// than [AppStatusChip] (no Material `Chip` padding), for card corners.
class AppStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const AppStatusPill({super.key, required this.label, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final fg = context.readable(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: icon == Icons.circle ? 8 : 14, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
