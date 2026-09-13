import 'package:flutter/material.dart';

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
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
