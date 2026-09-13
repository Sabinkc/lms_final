import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A single stat tile — icon, big value, label — the shared building block
/// for summary rows (Fees totals, Attendance breakdowns, etc.) that used to
/// be reimplemented per-feature as a private `_StatCard`/`_SummaryCard`
/// (see `reports_screen.dart`, `attendance_history_body.dart`,
/// `payroll_screen.dart`). Visually mirrors `QuickActionCard`'s tint
/// pattern so stat rows and the quick-actions grid read as one system.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatCard({super.key, required this.icon, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: AppRadius.card),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Lays out 2–4 [StatCard]s in a responsive row that wraps to two columns
/// on narrow widths rather than squeezing every tile — a `Wrap`-based
/// alternative to `reports_screen.dart`'s fixed-width private `_StatRow`.
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;

  const StatCardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = cards.length <= 2 || constraints.maxWidth >= 520 ? cards.length : 2;
        const spacing = AppSpacing.sm;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final card in cards) SizedBox(width: width, child: card)],
        );
      },
    );
  }
}
